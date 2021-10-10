import { Container } from "@chakra-ui/layout";
import React from "react";
import StreamBox from "./boxes/StreamBox";
import WrapBox from "./boxes/WrapBox";
import Header from "./header/header";

function App(): JSX.Element {
  return (
    <section>
      <Header></Header>
      <Container maxW="container.lg" centerContent>
        <WrapBox></WrapBox>
        <StreamBox></StreamBox>
      </Container>
    </section>
  );
}

export default App;
