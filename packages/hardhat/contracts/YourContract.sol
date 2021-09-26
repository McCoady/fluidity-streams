pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

import "hardhat/console.sol";

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; //"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract YourContract is SuperAppBase {
    ISuperfluid host; // Superfluid host contract
    IConstantFlowAgreementV1 cfa; // The stored constant flow agreement class address
    IInstantDistributionAgreementV1 ida; // The stored instant dist. agreement class address
    ISuperToken inputToken; // The input token (e.g. DAIx)
    ISuperToken outputToken; // The output token (e.g. ETHx)

    constructor(
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa,
        IInstantDistributionAgreementV1 _ida,
        ISuperToken _inputToken,
        ISuperToken _outputToken
    ) {
        host = _host;
        cfa = _cfa;
        ida = _ida;
        inputToken = _inputToken;
        outputToken = _outputToken;
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
        _host.registerApp(configWord);
    }

    function getNetFlow() public view returns (int96) {
        return _cfa.getNetFlow(_acceptedToken, address(this));
    }
}
