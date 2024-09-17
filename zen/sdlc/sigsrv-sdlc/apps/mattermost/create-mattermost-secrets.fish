#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "mattermost" $argv
end

set DATABASE_KUBE_NAME mattermost-db
set DATABASE_HOST $DATABASE_KUBE_NAME.mattermost.svc.cluster.local
set DATABASE_PORT 5432
set DATABASE_NAME mattermost
set DATABASE_USER mmuser
set DATABASE_PASSWORD ( \
    kubectl get secrets \
        $DATABASE_USER.$DATABASE_KUBE_NAME.credentials.postgresql.acid.zalan.do \
        -o jsonpath="{.data.password}" \
    | base64 --decode \
)

kubectl create secret generic \
    mattermost-db-conf \
    --from-literal=DB_CONNECTION_CHECK_URL="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" \
    --from-literal=DB_CONNECTION_STRING="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" \
    --from-literal=MM_SQLSETTINGS_DATASOURCEREPLICAS="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
