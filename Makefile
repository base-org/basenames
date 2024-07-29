include .env

# premint1 file should be minted with a 100-year duration, these are coinbase-specific domains
# 3153600000 = 100 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-testnet-premint-1
execute-testnet-premint-1:
	@for name in $$(cat script/premint/premint1); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 3153600000 \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint2 file should be minted with a 10-year duration, these are web2-specific domains
# 315360000 = 10 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-testnet-premint-2
execute-testnet-premint-2:
	@for name in $$(cat script/premint/premint2); \
	do \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 315360000 \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint3 file should be minted with a 5-year duration, these are web3-specific domains
# 157680000 = 5 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-testnet-premint-3
execute-testnet-premint-3:
	@for name in $$(cat script/premint/premint3); \
	do \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 157680000 \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint1 file should be minted with a 100-year duration, these are coinbase-specific domains
# 3153600000 = 100 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-1
execute-premint-1:
	@for name in $$(cat script/premint/premint1); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 3153600000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint2 file should be minted with a 10-year duration, these are web2-specific domains
# 315360000 = 10 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-2
execute-testnet-premint-2:
	@for name in $$(cat script/premint/premint2); \
	do \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 315360000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint3 file should be minted with a 5-year duration, these are web3-specific domains
# 157680000 = 5 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-3
execute-testnet-premint-3:
	@for name in $$(cat script/premint/premint3); \
	do \
		forge script script/premint/Premint.s.sol --sig "run(string,uint256)" "$$name" 157680000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

write-ids:
	@for name in $$(cat script/premint/premint1); \
	do \
		echo "$$name"; \
		forge script script/Scratch.s.sol --ffi --sig "run(string)" "$$name"; \
	done