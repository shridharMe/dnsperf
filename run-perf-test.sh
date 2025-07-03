
#!/bin/sh -xe

# Use environment variables for test parameters, with sane defaults
TEST_DURATION=${TEST_DURATION:-120}
CONCURRENT_CLIENTS=${CONCURRENT_CLIENTS:-20}
QUERIES_PER_SECOND=${QUERIES_PER_SECOND:-100}

# Dynamically find the CoreDNS service IP address
KUBE_DNS_IP=$(kubectl get svc kube-dns -n kube-system -o jsonpath='{.spec.clusterIP}')
echo "##################################################"
echo "Starting CoreDNS performance test..."
echo "Target DNS Server (CoreDNS): $KUBE_DNS_IP"
echo "Test Duration: ${TEST_DURATION} seconds"
echo "Concurrent Clients: ${CONCURRENT_CLIENTS}"
echo "Total Queries Per Second (all clients): ${QUERIES_PER_SECOND}"
echo "##################################################"

# Run dnsperf with specified parameters
# -l : time limit in seconds
# -c : number of clients to act as
# -Q : queries per second limit
dnsperf -s $KUBE_DNS_IP -d /data/queries.txt -l ${TEST_DURATION} -c ${CONCURRENT_CLIENTS} -Q ${QUERIES_PER_SECOND}

echo "##################################################"
echo "DNS performance test finished."

