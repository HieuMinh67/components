import React from "react"
import Greeting from "../components/greeting"
import { Link } from "gatsby"

// Rendering the <Greeting> component
const SayHello = () => {
  return (
    <div>
      <ul>
        <li>
          <Link to="/">Back to Home</Link>
        </li>
        <li>
          <Link to="/about">About me</Link>
        </li>
      </ul>
      <Greeting name="Megan" />
      <Greeting name="Obinna" />
      <Greeting name="Generosa" />
      <Greeting name="Greeting with children">
        I am your child
      </Greeting>
    </div>
  )
}

export default SayHello