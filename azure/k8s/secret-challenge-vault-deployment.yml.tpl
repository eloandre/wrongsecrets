apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: secret-challenge
    aadpodidbinding: wrongsecrets-pod-id
  name: secret-challenge
  namespace: default
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: secret-challenge
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: "2020-10-28T20:21:04Z"
      labels:
        app: secret-challenge
        aadpodidbinding: wrongsecrets-pod-id
      name: secret-challenge
    spec:
      securityContext:
        runAsUser: 2000
        runAsGroup: 2000
        fsGroup: 2000
      serviceAccountName: vault
      volumes:
        - name: 'ephemeral'
          emptyDir: {}
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "azure-wrongsecrets-vault"
      containers:
        - image: jeroenwillemsen/wrongsecrets:1.7.1-k8s-vault
          imagePullPolicy: IfNotPresent
          name: secret-challenge
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault
          ports:
            - containerPort: 8080
              protocol: TCP
          readinessProbe:
            httpGet:
              path: '/actuator/health/readiness'
              port: 8080
            initialDelaySeconds: 30
            timeoutSeconds: 5
            periodSeconds: 5
            failureThreshold: 8
          livenessProbe:
            httpGet:
              path: '/actuator/health/liveness'
              port: 8080
            initialDelaySeconds: 35
            timeoutSeconds: 30
            periodSeconds: 40
            failureThreshold: 5
          resources:
            requests:
              memory: '256Mi'
              cpu: '200m'
              ephemeral-storage: '1Gi'
            limits:
              memory: '512Mi'
              cpu: '1200m'
              ephemeral-storage: '2Gi'
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          env:
            - name: K8S_ENV
              value: azure
            - name: SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTYSOURCEENABLED
              value: "true"
            - name: SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTYSOURCES_0_NAME
              value: wrongsecret-3
            - name: SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTYSOURCES_0_ENDPOINT
              value: ${AZ_VAULT_URI}
            - name: SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTYSOURCES_0_CREDENTIAL_CLIENTID
              value: ${AZ_POD_CLIENT_ID}
            - name: SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTYSOURCES_0_CREDENTIAL_MANAGEDIDENTITYENABLED
              value: "true"
            - name: SPECIAL_K8S_SECRET
              valueFrom:
                configMapKeyRef:
                  name: secrets-file
                  key: funny.entry
            - name: SPECIAL_SPECIAL_K8S_SECRET
              valueFrom:
                secretKeyRef:
                  name: funnystuff
                  key: funnier
            - name: CHALLENGE33
              valueFrom:
                secretKeyRef:
                  name: challenge33
                  key: answer
            - name: SPRING_CLOUD_VAULT_URI
              value: "http://vault.vault.svc.cluster.local:8200"
            - name: JWT_PATH
              value: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          volumeMounts:
            - name: secrets-store-inline
              mountPath: "/mnt/secrets-store"
              readOnly: true
            - name: 'ephemeral'
              mountPath: '/tmp'
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      terminationGracePeriodSeconds: 30
