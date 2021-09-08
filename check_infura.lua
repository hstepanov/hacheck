#!/usr/bin/lua
--
--------------------
-- test checkalka --
--------------------
--
local https = require("ssl.https");
local ltn12 = require("ltn12");
local cjson = require("cjson");
https.TIMEOUT = 0.3
-- check sync status
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}]]
local body, code, headers, status = https.request{
    url = "https://mainnet.infura.io/v3/7d7390e3443c4546a8e4b9c3ad33ae1a",
    method = "POST",
    headers =
        {
            ["Content-Type"] = "application/json";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
}
-- if response or code != 200 ...
if not body or code ~= 200 then
    print("parity request failed:", status)
    os.exit(1)
    return
end
data = cjson.decode(table.concat(response_body))
if data.result then
    print(string.format("parity syncing: %s, %s, %s",
        data.result.startingBlock,
        data.result.currentBlock,
        data.result.highestBlock
    ))
    return
end
-- check latest block timestamp
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}]]
local body, code, headers, status = https.request{
    url = "https://mainnet.infura.io/v3/7d7390e3443c4546a8e4b9c3ad33ae1a",
    method = "POST",
    headers =
        {
            ["Content-Type"] = "application/json";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
}
if not body or code ~= 200 then
    print("Can't get number of most recent block:", status)
    os.exit(1)
    return
end
data = cjson.decode(table.concat(response_body))
block_number = data.result
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["%s",false],"id":1}]]
local request_body = string.format(request_body, block_number)
local body, code, headers, status = https.request{
    url = "https://mainnet.infura.io/v3/7d7390e3443c4546a8e4b9c3ad33ae1a",
    method = "POST",
    headers =
        {
            ["Content-Type"] = "application/json";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
}
if not body or code ~= 200 then
    print("Parity req failed:", status)
    os.exit(1)    
    return
end
data = cjson.decode(table.concat(response_body))
timestamp = tonumber(data.result.timestamp)
--if timestamp < os.time() - {{ parity_old_block }} then
if timestamp < os.time() - 100 then
    print("Latest block too old", timestamp)
    os.exit(1)
    return 
end
-- in case of success checks return:
print("Success\n")
