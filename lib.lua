-- local modname = ...
-- local Lib = {}
-- _G[modname] = Lib
-- 以上这样写，这个模块的名字就取决于该文件名
local Lib = Lib or {};
_G["Lib"] = Lib;

function Lib:TableEqual(value1, value2)
	local szType1 = type(value1);
	local szType2 = type(value2);

	if szType1 ~= szType2 then
		return false
	end

	if szType1 ~= "table" then
		if value1 ~= value2 then
			return false;
		end
	else
		for key, value in pairs(value1) do
			if value2[key] == nil or self:TableEqual(value2[key], value) == false then
				return false;
			end
		end
	end

	return true;
end

function Lib:SplitStr(szStrConcat, szSep)
	szSep	= szSep or ",";
	
	local tbStrElem = {};
	local nStart = 1;
	while true do
		local nAt = string.find(szStrConcat, szSep, nStart);
		table.insert(tbStrElem, string.sub(szStrConcat, nStart, nAt and nAt - 1));
		if (not nAt) then
			break;
		end
		nStart = nAt + #szSep;
	end
	return tbStrElem;
end

Lib.tbTypeOrder = {
	["nil"] = 1, ["number"] = 2, ["string"] = 3, ["userdata"] = 4, ["function"] = 5, ["table"] = 6,
};
Lib.TYPE_COUNT = 6;	-- 类型数量

function Lib:TypeId(szType)
	if self.tbTypeOrder[szType] then
		return self.tbTypeOrder[szType];
	end;
	self.TYPE_COUNT = self.TYPE_COUNT + 1;
	self.tbTypeOrder[szType] = self.TYPE_COUNT;
	return self.TYPE_COUNT;
end;

-- 修正出现死循环
function Lib:ShowTB(tbVar, nCount)
	-- 已经访问过的table表
	local tbVisitTable = {};
	
	tbVisitTable[tbVar] = 1;

	local function _ShowTBDetail(tbVar, szBlank, nCount)
		if (not szBlank) then
			szBlank = "";
		end;

		nCount = nCount or 0;
		if nCount > 10000 then
			print("ERROE~~ 层数太多，超过了1万次，防止死循环！！！！");
			return 0;
		end
		
		local tbType = {};
		for k, v in pairs(tbVar) do
			local nType = self:TypeId(type(v));
			if (not tbType[nType]) then
				tbType[nType] = {n = 0, name = type(v)};
			end;
			local tbTmp = tbType[nType];
			tbTmp.n = tbTmp.n + 1;
			tbTmp[tbTmp.n] = k;
		end
		
		for i = 1, self.TYPE_COUNT do
			if tbType[i] then
				local tbTmp = tbType[i];
				local szType = tbTmp.name;
				for i = 1, tbTmp.n do
					local key = tbTmp[i];
					local value = tbVar[key];
					local str;
					if (type(key) == "number") then
						str = szBlank.."["..key.."]";
					else
						str = szBlank.."."..key;
					end;
					if (szType == "nil") then
						print(str.."\t= nil");
					elseif (szType == "number") then
						print(str.."\t= "..tbVar[key]);
					elseif (szType == "string") then
						print(str..'\t= "'..tbVar[key]..'"');
					elseif (szType == "function") then
						print(str.."()");
					elseif (szType == "table") then
						if (tbVar[key] == tbVar) then
							print(str.."\t= {...}(self)");
						elseif tbVisitTable[tbVar[key]] then
							print(str.."\t= {...}(visited)");
						else
							print(str..":");
							tbVisitTable[tbVar[key]] = 1;
							_ShowTBDetail(tbVar[key], str, nCount+1);
						end;
					elseif (szType == "userdata") then
						print(str.."*");
					else
						print(str.."\t= "..tostring(tbVar[key]));
					end
					nCount = nCount + 1;
				end
			end
		end
	end
	
	_ShowTBDetail(tbVar or {}, nil, nCount);
end

function Lib:CountTable(tbVar)
	local tbCountTable = {}
	local nCount = 1;
	local nMaxCount = 9999;
	tbCountTable[tbVar] = 1

	local function _CountTable(tbVar, nCount, name, bPrint) 
		bPrint = bPrint or true
		if nCount > 10 then
			bPrint = false
		end

		local nElemCount = 0;

		if nCount > nMaxCount then
			print("Max Table Deep");
			Lib:ShowTB(tbVar);
			return
		end

		local tbType = {};
		for k, v in pairs(tbVar) do
			local nType = self:TypeId(type(v));
			if (not tbType[nType]) then
				tbType[nType] = {n = 0, name = type(v)};
			end;
			local tbTmp = tbType[nType];
			tbTmp.n = tbTmp.n + 1;
			tbTmp[tbTmp.n] = k;
		end

		for i = 1, 5 do
			if tbType[i] then
				nElemCount = nElemCount + tbType[i].n
			end
		end

		if tbType[6] then
			local nMax = tbType[6].n
			for i = 1, nMax do
				local key = tbType[6][i]
				local value = tbVar[key]

				if value == tbVar then	-- 等于自己
				elseif tbCountTable[value] then -- 已经访问过的
					-- nElemCount = nElemCount + 1
					print("is visited")
				else
					tbCountTable[value] = 1
					nElemCount = nElemCount + _CountTable(value or {}, nCount + 1, key)
				end
			end
		end

		if bPrint ~= false then
			print("Count Table ", name, "the elem count is ", nElemCount, "the count is", nCount)
		end
		return nElemCount
	end

	local nElemCount = _CountTable(tbVar or {}, nCount)
	print("ElemCount :", nElemCount)
	return nElemCount;
end

function Lib:GetLocalOSPath(szClientPath)
	local szOSName = os.getenv("OS");
	local szRet = "";
	if string.find(szOSName, "Window") or string.find(szOSName, "window") then
		-- 有 windows，则转 / 为 \\
		szRet = string.gsub(szClientPath, "/", "\\");
	else
		szRet = string.gsub(szClientPath, "\\", "/");
	end

	print(szClientPath, szRet);

	return szRet;
end

-- 推导它的过程
-- 0、使用递归
-- 1、除了 table，其他都可以直接复制，table 需要 for
-- 2、key 值同样可能是一个 table，所以需要 _copy
-- 3、一个表中可能有指向相同内存块的两个结构，所以这个关系也需要被保留，这是 tbLookup 的由来
-- 4、matetable 是容易忽视的一个点
function Lib:Copy(tbData)
	local tbLookup = {};

	local function _copy(tbObj)
		-- type will back value:nil boolean number string function userdate thread and table
		-- only table need do the deep clone
		if type(tbObj) ~= "table" then
			return tbObj;
		elseif tbLookup[tbObj] then
            -- if meet this object before, just return old value
			return tbLookup[tbObj];
		end

		local tbNewObj = {};
		tbLookUp[tbObj] = tbNewObj;
		for key, value in pairs(tbObj) do
            -- not only the value maybe a table, the key also maybe a table
			tbNewObj[_copy(key)] = _copy(value);
		end

        -- table and userdate both have metatable, but userdate can not do deep clone(maybe you should not do this for it), so...
		return setmetatable(tbNewObj, getmetatable(tbObj));
	end

	return _copy(tbData);
end

------------------------------------------------
-- 以下是一种生成继承内的方法:
-- 1、父类在子类的 _tbBase 中
-- 2、NewClass 中子类会调用父类的 Init

-- 子类的__index 元方法，去 _tbBase 中查找
Lib._tbCommonMetatable = {
	__index = function (tb, key)
		-- 这样写不牵扯到 _tbBase 中的方法，是否这样孙子类无法访问父类？
		-- return rawget(tb, "_tbBase")[key];

		local tbRoot = tb;
		local tbRet = nil;
		repeat
			tbRet = rawget(tbRoot, "_tbBase")[key];
			tbRoot = rawget(tbRoot, "_tbBase");
		until(tbRet ~= nil or tbRoot == nil)

		return tbRet;
	end;
}

function Lib:NewClass(tbBaseClass, ...)
	local tbNew = {_tbBase = Lib:Copy(tbBaseClass)};
	setmetatable(tbNew, self._tbCommonMetatable);

	-- 处理 Init 函数
	local tbRoot = tbNew;
	local tbInit = {};
	repeat
		local fnInit = rawget(tbRoot, "Init")
		-- 找到子类中存在的 Init 函数
		if (type(fnInit) == "function") then
			table.insert(tbInit, fnInit, 1)
		end
		tbRoot = rawget(tbRoot, "_tbBase")
	until(tbRoot == nil)

	for _, fnInit in ipairs(tbInit) do
		fnInit(tbNew, ...);
	end

	return tbNew
end

-- Lua 书本上的

-- 在文件头中 _G() 已经可以让 return 省略掉了，但它写入了 _G 空间
-- 这个 return 也可以这样省略
-- package.loaded[modname] = Lib
-- package.loaded 即是 require 使用到的模块数组
-- modname 是文件头中注释赋值，即是 ...
-- 但以上写法依赖 require 的实现，虽然 return 也是因为 require 的实现，但写 return 应该是 require 的本意
-- require 抽象实现见下
--[[

function require (name)
	if not package.loaded[name] then
		-- 通过 findloader 获得加载器，这里抽象成一个函数，它会依次去 package.proload[]、Lua file、C++ Lib 中去找
		-- 如果是 lua file，那么这个 loader() 就是 loadfile()
		local loader = findloader(name)
		if loader == nil then
			error("unable to load module ".. name)
		end

		package.loaded[name] = true		-- 找到则先加上标记，以免后面的 loader 中产生循环
		local res = loader(name)
		if res ~= nil then
			package.loaded[name] = res
		end
	end

	return package.loaded[name]
end

--]]
return Lib;
