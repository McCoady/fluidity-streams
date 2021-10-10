import React from "react";
import { Badge, Box, Heading, Input } from "@chakra-ui/react";
import { Button } from "@chakra-ui/react";
import { Select } from "@chakra-ui/react";

function WrapBox(): JSX.Element {
  return (
    <>
      <Box
        width={["100%", "90%", "60%", "50%"]}
        boxShadow="dark-lg"
        borderWidth="1px"
        borderRadius="lg"
        mb="3"
      >
        <Select size="sm" variant="outline" colorScheme="pink">
          <option value="ETH">ETH</option>
          <option value="ETHx">ETHx</option>
          <option value="DAI">DAI</option>
          <option value="DAIx">DAIx</option>
        </Select>

        <Box p="6">
          <Box
            display="flex"
            alignItems="center"
            justifyContent="space-between"
          >
            <Badge borderRadius="full" px="2" colorScheme="pink">
              From
            </Badge>
            <Box
              color="gray.500"
              fontWeight="semibold"
              letterSpacing="wide"
              fontSize="xs"
              textTransform="uppercase"
            >
              Balance: 0.1
            </Box>
          </Box>

          <Box
            mt="5"
            display="flex"
            alignItems="center"
            justifyContent="space-between"
          >
            <Input
              color="gray.300"
              fontWeight="semibold"
              letterSpacing="wide"
              fontSize="2xl"
              textTransform="uppercase"
              variant="unstyled"
              placeholder="0.0 Eth"
            ></Input>

            <Button size="xs" colorScheme="pink">
              Max
            </Button>
          </Box>
        </Box>
      </Box>
      <Heading size="md">To</Heading>
      <Box
        width={["100%", "90%", "60%", "50%"]}
        boxShadow="dark-lg"
        borderWidth="1px"
        borderRadius="lg"
        mt="3"
      >
        <Box p="6">
          <Badge borderRadius="full" px="2" colorScheme="pink">
            To
          </Badge>

          <Box
            color="gray.300"
            fontWeight="semibold"
            letterSpacing="wide"
            fontSize="2xl"
            mt="5"
          >
            0.01 ETHx
          </Box>
        </Box>
      </Box>
    </>
  );
}

export default WrapBox;
