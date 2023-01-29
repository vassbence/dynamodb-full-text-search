import type { APIGatewayProxyHandlerV2 } from "aws-lambda";
import { restoreDatabase, search } from "@/lib/lyra";

export const handler: APIGatewayProxyHandlerV2 = async function (event) {
  const query = event.queryStringParameters?.query;

  if (!query) {
    return {
      statusCode: 400,
      body: "Missing query parameter",
    };
  }

  const db = await restoreDatabase();

  const searchResults = await search(db, { term: query });

  return {
    statusCode: 200,
    body: JSON.stringify({
      results: searchResults.hits.map((hit) => hit.document),
    }),
  };
};
