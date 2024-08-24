import json


def main():

    owners = []
    with open("cache/Update-BNS-Users.json", "r") as f:
        data = json.load(f)
        for r in data:
            if(len(r["owners"]) > 1): 
                print("multiple owners for %s" % r["name"])
            elif(len(r["owners"]) == 0):
                print("no owners for %s" % r["name"])
            else:
                owners.append(r["owners"][0]["owner_address"])


    seen = set()
    owner_count = dict()
    unique_owners = []
    for owner in owners:
        if owner not in seen:
            unique_owners.append(owner)
            seen.add(owner)
            owner_count[owner] = 1
        else:
            owner_count[owner] += 1

    
    with open("cache/bns.csv", "a") as f:
        for owner in unique_owners:
            f.write(owner + "\n")
            
    
    print("Total owned tokens: %s" % len(owners))
    print("Total unique owners: %s" % len(unique_owners))
    c = 0
    for w in sorted(owner_count, key=owner_count.get):
        if owner_count[w] > 9:
            c+=1
            print(w, owner_count[w])
    print("Multiple name holders: %s" % str(c))

if __name__ == "__main__":
    main()