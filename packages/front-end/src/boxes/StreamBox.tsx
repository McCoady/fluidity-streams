import { Button } from "@chakra-ui/button";
import { Input } from "@chakra-ui/input";
import { Badge, Box, Center, Heading, Spacer } from "@chakra-ui/layout";
import React from "react";

function StreamBox(): JSX.Element {
  return (
    <Box
      width={["100%", "90%", "60%", "50%"]}
      boxShadow="dark-lg"
      borderWidth="1px"
      borderRadius="lg"
      mt="10"
    >
      <Heading mt="4" textAlign="center" size="sm">
        Stream DAIx to ETH
      </Heading>
      <Box p="6">
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box
            color="gray.500"
            fontWeight="semibold"
            letterSpacing="wide"
            fontSize="xs"
            textTransform="uppercase"
          >
            Balance: 0.1 DAIx
          </Box>
          <Badge borderRadius="full" px="2" colorScheme="pink">
            Streaming
          </Badge>
        </Box>

        <Center mt="5" display="flex" alignItems="center">
          <Box flex="1">
            <Box flex="1">
              <Input
                color="gray.300"
                fontWeight="semibold"
                letterSpacing="wide"
                fontSize="2xl"
                textTransform="uppercase"
                variant="unstyled"
                placeholder="0.0 DAIx"
              ></Input>
              <Button size="xs" colorScheme="pink">
                Start/Edit
              </Button>
            </Box>
          </Box>

          <Box
            color="gray.300"
            fontWeight="semibold"
            letterSpacing="wide"
            fontSize="xl"
            textAlign="right"
            flex="2"
          >
            0.02 DAIx/Month
          </Box>
        </Center>
      </Box>
    </Box>
  );
}

export default StreamBox;
