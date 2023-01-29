import { create, insertBatch } from "@lyrasearch/lyra";
import { Lyra, PropertiesSchema } from "@lyrasearch/lyra/dist/types";
import {
  restoreFromFile,
  persistToFile,
} from "@lyrasearch/plugin-data-persistence";
const { existsSync } = require("fs");
import { dynamo, ScanCommandInput, DYNAMO_TABLE } from "@/lib/dynamodb";

export * from "@lyrasearch/lyra";

const DB_PATH = `${process.env.MOUNT_PATH}/db.json`;

export async function persistDatabase(db: Lyra<PropertiesSchema>) {
  await persistToFile(db, "json", DB_PATH);
}

export async function restoreDatabase() {
  if (!existsSync(DB_PATH)) {
    const db = await create({
      schema: {
        pk: "string",
        sk: "string",
        test_full_text_searchable_attribute: "string",
      },
    });

    const scan: ScanCommandInput = {
      TableName: DYNAMO_TABLE,
      FilterExpression:
        "attribute_exists(#test_full_text_searchable_attribute)",
      ExpressionAttributeNames: {
        "#test_full_text_searchable_attribute":
          "test_full_text_searchable_attribute",
      },
    };

    let cursor;
    const items = [];

    do {
      scan.ExclusiveStartKey = cursor;
      const { Items, LastEvaluatedKey } = await dynamo.scan(scan);

      items.push(...(Items ?? []));
      cursor = LastEvaluatedKey;
    } while (cursor);

    await insertBatch(db, items as any, { id: (doc) => `${doc.pk}#${doc.sk}` });

    await persistDatabase(db);

    return db;
  }

  const db = await restoreFromFile("json", DB_PATH);

  return db;
}
