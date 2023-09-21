import {blue} from "./style.module.css";

import React from "react";

// Defining the <Greeting> component
const Greeting = (props: any) => {
  return (
    <div>
      <h3>Hi {props.name}!</h3>
      <h5 className={blue}>Children is {props.children}</h5>
    </div>
  );
};

export default Greeting;
