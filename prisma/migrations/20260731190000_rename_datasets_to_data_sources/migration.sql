-- RenameTable (preserve existing rows instead of drop+create)
ALTER TABLE "ref_datasets" RENAME TO "ref_data_sources";
ALTER TABLE "ref_data_sources" RENAME CONSTRAINT "ref_datasets_pkey" TO "ref_data_sources_pkey";
ALTER INDEX "ref_datasets_code_key" RENAME TO "ref_data_sources_code_key";

-- CreateTable
CREATE TABLE "ref_block_data_sources" (
    "id" SERIAL NOT NULL,
    "block_id" VARCHAR(100) NOT NULL,
    "data_source_id" INTEGER NOT NULL,
    "calculation_rule" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ref_block_data_sources_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ref_block_data_sources_block_id_key" ON "ref_block_data_sources"("block_id");

-- AddForeignKey
ALTER TABLE "ref_block_data_sources" ADD CONSTRAINT "ref_block_data_sources_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "ref_data_sources"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
