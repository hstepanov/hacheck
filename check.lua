#!/usr/bin/lua
--
--------------------
-- test checkalka --
--------------------
--
local http = require("socket.http");
local ltn12 = require("ltn12");
local cjson = require("cjson");
http.TIMEOUT = 0.3
-- check sync status
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}]]
local res, code = http.request{
    url = "http://127.0.0.1:8545/",
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
if not res or code ~= 200 then
    ngx.status = 503
    ngx.say("parity request failed: ", code)
    return
end
data = cjson.decode(table.concat(response_body))
if data.result then
    ngx.status = 503
    ngx.say(string.format("parity syncing: %s, %s, %s",
        data.result.startingBlock,
        data.result.currentBlock,
        data.result.highestBlock
    ))
    return
end
-- check latest block timestamp
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}]]
local res, code = http.request{
    url = "http://127.0.0.1:8545/",
    method = "POST",
    headers =
        {
            ["Content-Type"] = "application/json";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
}
if not res or code ~= 200 then
    ngx.status = 503
    ngx.say("parity request failed: ", code)
    return
end
data = cjson.decode(table.concat(response_body))
block_number = data.result
local response_body = {}
local request_body = [[{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["%s",false],"id":1}]]
local request_body = string.format(request_body, block_number)
local res, code = http.request{
    url = "http://127.0.0.1:8545/",
    method = "POST",
    headers =
        {
            ["Content-Type"] = "application/json";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
}
if not res or code ~= 200 then
    ngx.status = 503
    ngx.say("parity request failed: ", code)
    return
end
data = cjson.decode(table.concat(response_body))
timestamp = tonumber(data.result.timestamp)
if timestamp < os.time() - {{ parity_old_block }} then
    ngx.status = 503
    ngx.say("latest block too old: ", timestamp)
    return
end
