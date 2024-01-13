#!/usr/bin/env fish

set DATABASE_KUBE_CONTEXT sigsrv-prod
set DATABASE_KUBE_NAMESPACE mattermost
set DATABASE_KUBE_NAME mattermost-db
set DATABASE_HOST $DATABASE_KUBE_NAME.$DATABASE_KUBE_NAMESPACE.svc.cluster.local
set DATABASE_PORT 5432
set DATABASE_NAME mattermost
set DATABASE_USER mmuser
set DATABASE_PASSWORD ( \
    kubectl get secrets \
        --context $DATABASE_KUBE_CONTEXT \
        -n $DATABASE_KUBE_NAMESPACE \
        $DATABASE_USER.$DATABASE_KUBE_NAME.credentials.postgresql.acid.zalan.do \
        -o jsonpath="{.data.password}" \
    | base64 --decode \
)

kubectl create secret generic\
    --context $DATABASE_KUBE_CONTEXT \
    -n $DATABASE_KUBE_NAMESPACE \
    mattermost-db-conf \
    --from-literal=DB_CONNECTION_CHECK_URL="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" \
    --from-literal=DB_CONNECTION_STRING="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" \
    --from-literal=MM_SQLSETTINGS_DATASOURCEREPLICAS="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
