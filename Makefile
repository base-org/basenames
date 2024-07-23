include .env

.PHONY: execute-testnet-premint
execute-testnet-premint:
	@for name in $$(cat premint); \
	do \
		forge script script/Premint.s.sol --sig "run(string)" "$$name" --rpc-url $(BASE_SEPOLIA_RPC_URL); \
	done

.PHONY: execute-premint
execute-premint:
	@for name in $$(cat premint); \
	do \
		forge script script/Premint.s.sol --sig "run(string)" "$$name" --rpc-url $(BASE_RPC_URL); \
	done
