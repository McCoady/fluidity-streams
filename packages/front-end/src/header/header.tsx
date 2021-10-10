import { Button } from "@chakra-ui/button";
import { Box, Flex, Heading, Spacer } from "@chakra-ui/layout";
import { useEtherBalance, useEthers } from "@usedapp/core";
import React from "react";

function Header() {
  const { activateBrowserWallet, account } = useEthers();

  return (
    <>
      <Flex px="10" py={5}>
        <Box>
          <Heading size="xl">Fluidity Streams</Heading>
        </Box>
        <Spacer />
        <Box pr="10">
          <Button
            disabled={Boolean(account)}
            colorScheme="pink"
            onClick={() => {
              if (!account)
                activateBrowserWallet((error) => {
                  console.error("error", error);
                });
            }}
          >
            {account
              ? account.slice(0, 10) + "..." + account.slice(32, 42)
              : "Connect Wallet"}
          </Button>
        </Box>
      </Flex>
    </>
  );
}

export default Header;
