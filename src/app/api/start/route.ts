import { NextResponse } from "next/server";
const {
  CloudFormationClient,
  UpdateStackCommand,
  DescribeStacksCommand,
} = require("@aws-sdk/client-cloudformation");

const CORRECT_PASSWORD = process.env.SERVER_PASSWORD; // Use env variables in production
let serverStatus = "stopped";

const cloudformation_client = new CloudFormationClient({
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.ACCESS_KEY,
    secretAccessKey: process.env.SECRET_KEY,
  },
});
export async function POST(req: Request) {
  try {
    const { password } = await req.json();
    const stackName = "boys-factorio";
    let serverState = "Stopped";

    if (password !== CORRECT_PASSWORD) {
      return NextResponse.json({ error: "Invalid password" }, { status: 401 });
    }

    const command = new DescribeStacksCommand({
      StackName: stackName,
    });

    try {
      const response = await cloudformation_client.send(command);
      const stack = response.Stacks[0];
      if (!stack) {
        throw new Error(`Stack ${stackName} not found`);
      }

      const serverState = stack.Parameters.find(
        (param: any) => param.ParameterKey === "ServerState"
      )?.ParameterValue;
      console.log("ServerState value:", serverState);
    } catch (error) {
      console.error("Error getting stack parameters:", error);
      throw error;
    }

    if (serverState === "Running") {
      return NextResponse.json(
        { message: "Server is already running" },
        { status: 400 }
      );
    }

    const updateParams = {
      StackName: stackName,
      UsePreviousTemplate: true,
      Parameters: [
        {
          ParameterKey: "ServerState",
          ParameterValue: "Running",
        },
        {
          ParameterKey: "FactorioImageTag",
          ParameterValue: "stable",
        },
        {
          ParameterKey: "SpotPrice",
          ParameterValue: "0.08",
        },
      ],
      // Include Capabilities if your stack requires them
      Capabilities: ["CAPABILITY_IAM"],
    };

    // Add your actual server stop logic here
    serverStatus = "running";

    try {
      const command = new UpdateStackCommand(updateParams);
      const response = await cloudformation_client.send(command);
      console.log("Stack update initiated:", response.StackId);
    } catch (error) {
      console.error("Error updating stack:", error);
      throw error;
    }

    return NextResponse.json({ message: "Server is starting up" });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to run server" },
      { status: 500 }
    );
  }
}
