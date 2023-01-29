import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

export * from "@aws-sdk/lib-dynamodb";
export * from "@aws-sdk/util-dynamodb";

export const DYNAMO_TABLE = process.env.DYNAMO_TABLE;

const client = new DynamoDBClient({});
export const dynamo = DynamoDBDocument.from(client);
