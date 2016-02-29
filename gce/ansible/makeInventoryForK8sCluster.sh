kubectl get nodes | awk '{ print $1 }' | tee >( sed 's/NAME/[master]/' > inventory1 ) >( sed 's/NAME/\'$'\n[node]/' > inventory2 )
cat inventory1 inventory2 > inventory
rm inventory1 inventory2
