#!/usr/bin/bash
set -eu

### Configuration ###
gcloud config set project 'PROJECT ID HERE'
BUCKET='gs://BUCKET NAME HERE'
FIRESTORE_DB='(default)'
# make sure you type the collection names correctly, Firestore does not validate this and will just give you an empty table
FIRESTORE_COLLECTIONS='coll1,coll2,etc'
BQ_DATASET='mydataset'
BQ_LOCATION='europe-north1'
#####################

echo "Exporting data from Firestore ..."
export_prefix="$(gcloud firestore export "$BUCKET" "--collection-ids=$FIRESTORE_COLLECTIONS" "--database=$FIRESTORE_DB" --format=json | jq -r '.metadata.outputUriPrefix')"
[[ -z "$export_prefix" ]] && exit 1

for coll in ${FIRESTORE_COLLECTIONS//,/ }
do
    echo "Importing '${coll}' to BigQuery ..."
    bq load --replace --source_format=DATASTORE_BACKUP "${BQ_DATASET}.${coll}" "${export_prefix}/all_namespaces/kind_${coll}/all_namespaces_kind_${coll}.export_metadata"
done

echo "Cleaning up temporary files ..."
gcloud storage rm --recursive "$export_prefix"
