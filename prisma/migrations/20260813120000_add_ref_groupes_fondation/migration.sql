-- CreateTable
CREATE TABLE "ref_groupes_fondation" (
    "id" SERIAL NOT NULL,
    "groupe_code" VARCHAR(20) NOT NULL,
    "annee_fondation" INTEGER,
    "site_officiel" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ref_groupes_fondation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ref_groupes_fondation_groupe_code_key" ON "ref_groupes_fondation"("groupe_code");
