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

# premint2 file should be minted with a 10-year duration, these are cb exec domains
# 315360000 = 10 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-2
execute-premint-2:
	@for name in $$(cat script/premint/premint2); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 315360000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint3 file should be minted with a 5-year duration, these are web2-specific domains
# 157680000 = 5 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-3
execute-premint-3:
	@for name in $$(cat script/premint/premint3); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 157680000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint4 file should be minted with a 5-year duration, these are web3-specific domains/individuals
# 157680000 = 5 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-4
execute-premint-4:
	@for name in $$(cat script/premint/premint4); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 157680000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint5 file should be minted with a 5-year duration, these are web3-specific domains/individuals
# 157680000 = 5 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-5
execute-premint-5:
	@for name in $$(cat script/premint/premint5); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 157680000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint6 file should be minted with a 100-year duration, these are Coinbase/Base specific domains
# 3153600000 = 100 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-6
execute-premint-6:
	@for name in $$(cat script/premint/premint6); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 3153600000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint7 file should be minted with a 1-year duration, these are the F500 names
# 31536000 = 1 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-7
execute-premint-7:
	@for name in $$(cat script/premint/premint7); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 31536000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint8 file should be minted with a 1-year duration, these are the base BD names
# 31536000 = 1 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-8
execute-premint-8:
	@for name in $$(cat script/premint/premint8); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 31536000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done

# premint9 file should be minted with a 100-year duration, these are the base project words
# 3153600000 = 100 (years) * 365 (days) * 24 (hours) * 3600 (seconds)
.PHONY: execute-premint-9
execute-premint-9:
	@for name in $$(cat script/premint/premint9); \
	do \
		echo "$$name"; \
		forge script script/premint/Premint.s.sol --ffi --sig "run(string,uint256)" "$$name" 31536000 \
		--rpc-url $(BASE_RPC_URL) --fork-retries 5 --broadcast; \
	done
