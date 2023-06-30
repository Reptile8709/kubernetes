# SETUP KUBERNETES-CLUSTER USING SHELL SCRIPT WHICH NEEDS TO RUN IN BOTH THE MASTER & WORKER NODE


# 1. The Shell-Script will Only work In Red Hat Distribution ( i.e. Centos ).

# 2. Just Setup two Centos-Machine.

# 3. Run the k8s_master.sh  script first in Control-Plane only.

# 4. Choose the CNI-Network as per your Choice.

NOTE:
   Open the file kubeinit.log and check the Join-Token which need to paste in last-line of k8s_worker.sh file.

# 5. Then, Run the k8s_worker.sh Script in Worker-Node.

# 6. Goto Master & check Node is Ready Or Not using below command:
    i.e. kubectl get nodes