// Define the locations for the Lab deployment. max 2 locations. min 1 location.
param locations array = [
  {
    region: 'swedencentral'
    addressSpace: '172.16.0.0/16'
    hubSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
    spokeSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
    onPremSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
  }

  {
    region: 'germanywestcentral'
    addressSpace: '172.31.0.0/16'
    hubSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
    spokeSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
    onPremSubscriptionID: 'aaaaaaaaa-aaaa-aaaa-aaaaaaa'
  }
]

param deployA bool = false
param deployB bool = false
param deployC bool = false

// output array with union of unique subscriptions IDs from Locations array
output uniqueSubscriptionIDs array = union(
  deployA ? map(locations, loc => loc.hubSubscriptionID) : [],
  deployB ? map(locations, loc => loc.spokeSubscriptionID) : [],
  deployC ? map(locations, loc => loc.onPremSubscriptionID) : []
)
