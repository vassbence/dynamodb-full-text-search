import type { DynamoDBStreamHandler } from "aws-lambda";
import { restoreDatabase, persistDatabase, insert, remove } from "@/lib/lyra";
import { unmarshall } from "@/lib/dynamodb";

export const handler: DynamoDBStreamHandler = async function (event) {
  const db = await restoreDatabase();

  for (const record of event.Records) {
    if (!record?.eventName || !record?.dynamodb?.Keys) {
      continue;
    }

    // as any because of the following type mismatch: https://stackoverflow.com/questions/73572769/incompatible-types-of-attributevalue-in-dynamodb-streams
    const id = `${record.dynamodb.Keys.pk.S}#${record.dynamodb.Keys.sk.S}`;

    switch (record.eventName) {
      case "INSERT": {
        const item = unmarshall(record.dynamodb.NewImage as any);
        if (!item.test_full_text_searchable_attribute) {
          continue;
        }

        if (db.docs[id]) {
          continue;
        }

        await insert(db, item, { id: () => id });
        break;
      }
      case "MODIFY": {
        const item = unmarshall(record.dynamodb.NewImage as any);

        if (!db.docs[id]) {
          continue;
        }

        await remove(db, id);
        if (item.test_full_text_searchable_attribute) {
          await insert(db, item, { id: () => id });
        }
        break;
      }
      case "REMOVE": {
        if (!db.docs[id]) {
          continue;
        }

        await remove(db, id);
        break;
      }
    }
  }

  await persistDatabase(db);
};
