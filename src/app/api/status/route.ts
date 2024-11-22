import { NextResponse } from "next/server";
const { ECSClient, DescribeClustersCommand } = require("@aws-sdk/client-ecs");
const {
  CloudFormationClient,
  DescribeStacksCommand,
} = require("@aws-sdk/client-cloudformation");

const client = new ECSClient({
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.ACCESS_KEY,
    secretAccessKey: process.env.SECRET_KEY,
  },
});

const cfClient = new CloudFormationClient({
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.ACCESS_KEY,
    secretAccessKey: process.env.SECRET_KEY,
  },
});

export async function GET() {
  const stackName = "boys-factorio";

  const stackResponse = await cfClient.send(
    new DescribeStacksCommand({
      StackName: stackName, // Replace with your actual stack name
    })
  );

  const stackStatus = stackResponse.Stacks?.[0]?.StackStatus;

  // If stack is updating, return "working" status
  if (stackStatus === "UPDATE_IN_PROGRESS") {
    return NextResponse.json({ status: "working" });
  }

  const describeResponse = await client.send(
    new DescribeClustersCommand({
      clusters: ["boys-factorio-cluster"],
    })
  );

  // Check if there are clusters and if runningTasksCount is >= 1
  const status =
    describeResponse.clusters?.[0]?.runningTasksCount >= 1
      ? "running"
      : "stopped";

  return NextResponse.json({ status });
}
