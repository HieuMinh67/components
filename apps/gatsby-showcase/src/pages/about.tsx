// Step 1: Import React
import { Link } from "gatsby";
import * as React from "react";
import Layout from "../components/layout";

// Step 2: Define your component
const AboutPage = () => {
  return (
    <Layout pageTitle="Home Page">
      <p>I'm making this by following the Gatsby Tutorial.</p>
      <main>
        <h2>About Me</h2>
        <ul>
          <li>
            <Link to="/">Back to Home</Link>
          </li>
          <li>
            <Link to="/say-hello">Just wanna say hello</Link>
          </li>
        </ul>
        <p>
          Hi there! I'm the proud creator of this site, which I built with
          Gatsby.
        </p>
      </main>
    </Layout>
  );
};

// Step 3: Export your component
export default AboutPage;

// Step 4: Add title using https://www.gatsbyjs.com/docs/reference/built-in-components/gatsby-head/
export const Head = () => <title>About Me</title>;
