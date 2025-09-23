# Setup Guide 

After the deployment with terraform we have to configure keycloak and Minio for MEITREX. This guide illustrates steps 6 and 7 in the setup guide to assist users in setting up meitrex. 

## Step 6 Setup keycloak realm

We have to setup the keycloak realm. We simply navigate to the creator page and copy the contents of the realm file provided in this repository. 

1. Open the keycloak endpoint. For our deployment the endpoint is accessible under `dev.meitrex.de/keycloak` ![Keycloak login page](./images/keycloak-login.png)
2. Login into Keycloak with the default user credentials set in the variables file. ![Keycloak main page](./images/keycloak-main-page.png)
3. Click Manage realms page ![Keycloak create realm page](./images/keycloak-manage-realms.png)
4. Click Create realm button ![Keycloak create realm page](./images/keycloak-create-realms.png)
5. Import realm provided in this repository. Copy contents of GITS realm file into the form ![Keycloak import realm page](./images/keycloak-import-realms.png)
6. Press Create

## Step 6 Setup webhook for AI Service

We need the webhook because if we upload a file MINIO will use the webhook to notify the DocProcAI Service to start processing the new content. The webhook is already defined and configured in the helm chart. Currently we cant automatically ad webhook to the buckets so we have to do it manually. 

1. Open Minio endpoint. For our deployment the endpoint is accessible under `minio-dashboard.meitrex.de` ![Minio login page](./images/minio-login.png)
2. Login to MINIO with the default user credentials. ![Minio main page](./images/minio-main-page.png)
3. Select Buckets ![Minio bucket page](./images/minio-bucket-page.png)
4. Select one bucket e.g. audio ![Minio audio bucket page](./images/minio-audio-bucket-page.png)
5. Select events ![Minio event bucket page](./images/minio-bucket-event-page.png)
6. Press subscribe to event  ![Minio event subscription page](./images/minio-bucket-event-settings-page.png)
7. For APN select `arn:minio:sqs::onObjectCreated:webhook` leave Prefix and Suffix empty Select Event PUT ![Minio event bucket page](./images/minio-bucket-event-settings-formular.png)
8. Press Save

Repeat this for the buckets `document`, `presentation` and `video`.
