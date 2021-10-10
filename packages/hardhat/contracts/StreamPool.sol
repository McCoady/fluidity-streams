pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StreamPool is SuperAppBase {
    using SafeERC20 for ERC20;

    ISuperfluid _host; // Superfluid host contract
    IConstantFlowAgreementV1 _cfa; // The stored constant flow agreement class address
    IInstantDistributionAgreementV1 _ida; // The stored instant dist. agreement class address
    ISuperToken _inputToken; // The address of input token (e.g. DAIx)
    ISuperToken _outputToken; // The address of output token (e.g. ETHx)
    IUniswapV2Router02 _sushiRouter; //Sushiswap Router contract address
    uint32 outputIndexId;
    uint256 lastDistribution;

    event Distribution(uint256 distributionAmount, address outputToken);
    event UpdatedStream(address user, int96 userFlow, int96 totalFlow);

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        IInstantDistributionAgreementV1 ida,
        ISuperToken inputToken,
        ISuperToken outputToken,
        IUniswapV2Router02 sushiRouter
    ) payable {
        require(address(host) != address(0), "host");
        require(address(cfa) != address(0), "cfa");
        require(address(ida) != address(0), "ida");
        require(address(inputToken) != address(0), "inputToken");
        require(address(outputToken) != address(0), "output");
        require(!host.isApp(ISuperApp(msg.sender)), "owner SA");
        _host = host;
        _cfa = cfa;
        _ida = ida;
        _inputToken = inputToken;
        _outputToken = outputToken;
        _sushiRouter = sushiRouter;

        // Unlimited approve for sushiswap
        ERC20(_inputToken.getUnderlyingToken()).safeIncreaseAllowance(
            address(_sushiRouter),
            2**256 - 1
        );

        // and Supertoken upgrades
        ERC20(_inputToken.getUnderlyingToken()).safeIncreaseAllowance(
            address(_inputToken),
            2**256 - 1
        );

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
        host.registerApp(configWord);

        _createIndex(outputIndexId, outputToken);

        _updateSubscription(outputIndexId, msg.sender, 1, _outputToken);
    }

    function _updateOutflow(
        bytes calldata ctx,
        bytes calldata agreementData,
        bool distributeFirst
    ) private returns (bytes memory newCtx) {
        newCtx = ctx;

        (, , uint128 totalUnitsApproved, uint128 totalUnitsPending) = _ida
            .getIndex(_outputToken, address(this), outputIndexId);

        uint256 balance = ISuperToken(_inputToken).balanceOf(address(this)) /
            (10**(18 - ERC20(_inputToken.getUnderlyingToken()).decimals()));

        if (
            distributeFirst &&
            totalUnitsApproved + totalUnitsPending > 0 &&
            balance > 0
        ) {
            newCtx = _distribute(newCtx);
        }

        (address requester, address flowReceiver) = abi.decode(
            agreementData,
            (address, address)
        );
        int96 appFlowRate = _cfa.getNetFlow(_inputToken, address(this));
        (, int96 requesterFlowRate, , ) = _cfa.getFlow(
            _inputToken,
            requester,
            address(this)
        );

        emit UpdatedStream(requester, requesterFlowRate, appFlowRate);
    }

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata _agreementData,
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        returns (bytes memory newCtx)
    {
        address user = _host.decodeCtx(_ctx).msgSender;
        return _updateOutflow(_ctx, _agreementData, true);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata _agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        returns (bytes memory newCtx)
    {
        address customer = _host.decodeCtx(_ctx).msgSender;
        return _updateOutflow(_ctx, _agreementData, true);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata _agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    ) external override returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        //if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass)) return _ctx;
        (address customer, ) = abi.decode(_agreementData, (address, address));
        return _updateOutflow(_ctx, _agreementData, true);
    }

    function _swap(uint256 amount, uint256 deadline) public returns (uint256) {
        address tokenIn = _inputToken.getUnderlyingToken();
        address tokenOut = _sushiRouter.WETH();
        address[] memory path;
        uint256 outputAmount;

        _inputToken.downgrade(amount);

        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        _sushiRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            deadline
        );
        outputAmount = address(this).balance;

        _outputToken.upgrade(outputAmount);

        return outputAmount;
    }

    function _distribute(bytes memory ctx)
        internal
        returns (bytes memory newCtx)
    {
        newCtx = ctx;
        require(
            _host.isCtxValid(newCtx) || newCtx.length == 0,
            "Invalid Transaction"
        );

        _swap(
            ISuperToken(_inputToken).balanceOf(address(this)),
            block.timestamp + 3000
        );

        uint256 outputBalance = ISuperToken(_outputToken).balanceOf(
            address(this)
        );
        (uint256 actualAmount, ) = _ida.calculateDistribution(
            _outputToken,
            address(this),
            outputIndexId,
            outputBalance
        );

        if (actualAmount == 0) {
            return newCtx;
        }

        require(
            _outputToken.balanceOf(address(this)) >= actualAmount,
            "Balance not enough for distribution"
        );
        newCtx = _idaDistribute(
            outputIndexId,
            uint128(actualAmount),
            _outputToken,
            newCtx
        );

        emit Distribution(actualAmount, address(_outputToken));

        lastDistribution = block.timestamp;

        return newCtx;
    }

    function _idaDistribute(
        uint32 index,
        uint128 distAmount,
        ISuperToken distToken,
        bytes memory ctx
    ) internal returns (bytes memory newCtx) {
        newCtx = ctx;
        if (newCtx.length == 0) {
            // No context provided
            _host.callAgreement(
                _ida,
                abi.encodeWithSelector(
                    _ida.distribute.selector,
                    distToken,
                    index,
                    distAmount,
                    new bytes(0) // placeholder ctx
                ),
                new bytes(0) // user data
            );
        } else {
            require(
                _host.isCtxValid(newCtx) || newCtx.length == 0,
                "Ctx invalid"
            );
            (newCtx, ) = _host.callAgreementWithContext(
                _ida,
                abi.encodeWithSelector(
                    _ida.distribute.selector,
                    distToken,
                    index,
                    distAmount,
                    new bytes(0) // placeholder ctx
                ),
                new bytes(0), // user data
                newCtx
            );
        }
    }

    function _createIndex(uint256 index, ISuperToken distToken) internal {
        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.createIndex.selector,
                distToken,
                index,
                new bytes(0) // placeholder ctx
            ),
            new bytes(0) // user data
        );
    }

    function _updateSubscription(
        uint256 index,
        address subscriber,
        uint128 shares,
        ISuperToken distToken
    ) internal {
        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.updateSubscription.selector,
                distToken,
                index,
                subscriber,
                shares / 1e9,
                new bytes(0) // placeholder ctx
            ),
            new bytes(0) // user data
        );
    }

    function distribute() public {
        _distribute(new bytes(0));
    }

    function getNetFlow() public view returns (int96) {
        return _cfa.getNetFlow(_inputToken, address(this));
    }

    function getUserStream(address user)
        public
        view
        returns (int96 requesterFlowRate)
    {
        (, requesterFlowRate, , ) = _cfa.getFlow(
            _inputToken,
            user,
            address(this)
        );
    }

    function getInputToken() public view returns (ISuperToken) {
        return _inputToken;
    }

    function getOutputToken() public view returns (ISuperToken) {
        return StreamPool._outputToken;
    }

    function getSushiAddress() public view returns (address) {
        return address(_sushiRouter);
    }

    function getLastDistribution() public view returns (uint256) {
        return lastDistribution;
    }

    function getPoolBalance() public view returns (uint256) {
        return _inputToken.balanceOf(address(this));
    }

    //get number of users flowing

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_inputToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return
            ISuperAgreement(agreementClass).agreementType() ==
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            );
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "SatisfyFlows: not accepted token");
        require(_isCFAv1(agreementClass), "SatisfyFlows: only CFAv1 supported");
        _;
    }
}
