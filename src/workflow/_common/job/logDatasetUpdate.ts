import {prisma} from "../../../../prisma/prisma";


async function main() {
    await prisma.monitorDataSetsUpdate.create({});
    console.log("📅 Dataset update logged");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());