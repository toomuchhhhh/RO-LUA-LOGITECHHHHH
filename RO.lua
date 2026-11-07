-- ===== เปิด/ปิดฟังก์ชัน (true = เปิด, false = ปิด) =====
local enableFunc1 = true   -- ฟังก์ชัน 1: กวาด (กด 1 + คลิกซ้าย) ,false , true
local enableFunc2 = true   -- ฟังก์ชัน 2: สลับชุด Greed (Z, C, X) เก็บของ ,false , true
local enableFunc3 = true   -- ฟังก์ชัน 3: ลำดับเทเล (6, F9, Enter, 5) ,false  , true

-- เปิด/ปิดปุ่มเสริม (true = เปิด, false = ปิด)
local enableF1 = true   -- F1 (กดตอนเริ่ม แล้วกดซ้ำตามรอบ f1Interval) ,false , true
local enableF5 = false  -- F5 (กดตอนเริ่ม แล้วกดซ้ำทุกรอบรูทีน) ,false , true
local enableF6 = true   -- F6 (กดตอนเริ่ม แล้วกดซ้ำตามรอบ f6Interval) ,false , true

-- กดครั้งแรกตอนเริ่ม: ลำดับ F1 -> F5 -> F6 รอระหว่างปุ่มเท่านี้ (ms)
local startKeysGap = 500

-- ===== ตั้งค่าพื้นที่กวาด =====
-- ขนาดจอมอนิเตอร์จริง (ใช้แปลงพิกเซลเป็นหน่วย G HUB)
local screenW, screenH = 2560, 1440

-- ขนาดหน้าต่างเกม (Window Mode)
local gameW, gameH = 1024, 768

-- พื้นที่กวาดเป็น % ของหน้าต่างเกม ศูนย์กลางคือตำแหน่งเม้าตอนกดปุ่ม 4
-- ลดเหลือ 14 ให้ของตกอยู่ในรัศมี Greed (5x5) เป็นส่วนใหญ่ (เดิม 27.3)
local areaWPercent = 19
local areaHPercent = 19

local areaW = gameW * areaWPercent / 100   -- ขนาดพื้นที่กวาด (พิกเซล)
local areaH = gameH * areaHPercent / 100

local gridSize = 7

-- ===== ความเร็ว (ms) =====
local moveDelay = 25      -- รอหลังเลื่อนเม้า
local holdKey = 12        -- กดค้างปุ่ม 1
local gapDelay = 8        -- ช่องว่างระหว่างปุ่ม 1 กับคลิก
local holdClick = 18      -- กดค้างคลิกซ้าย
local afterDelay = 10     -- รอหลังคลิก

-- ===== ตั้งเวลา =====
local routineInterval = 6500  -- ทุกกี่ ms เริ่มรูทีน Greed + เทเล (5000, 10000-15000 ปกติ)

-- ===== ฟังก์ชัน 2: สลับชุด Greed แล้วเก็บของ =====
local swapToGreedKeys = { "z" }  -- Z = สลับเป็นชุด Greed (ทำครั้งเดียวตอนเริ่ม)
local greedKeys    = { "c" }  -- C = Greed
local greedKeyGap  = 0           -- รอระหว่างปุ่มใน greedKeys
local swapBackKeys = { "x" }       -- X = สลับกลับ ทำครั้งเดียวหลัง Greed ครบทุกรอบ
local swapHold    = 60
local swapGap     = 100    -- รอหลังกดแต่ละปุ่มสลับชุด
local swapSettle  = 150    -- รอให้ชุดเปลี่ยนเสร็จก่อนกด Greed

local swapBackSettle = 60   -- รอหลังกด X (ก่อนเข้าลำดับเทเล)
local greedHold   = 50
local greedGap    = 300    -- ms ต้อง >= after-cast delay ของ Greed
local dropWait    = 200    -- รอให้มอนตัวสุดท้ายตายและของตกก่อนเริ่ม

-- เดินสุ่มทิศแล้ว Greed ซ้ำ (เก็บของที่ตกนอกรัศมี Greed รอบแรก)
local extraGreeds  = 1      -- Greed เพิ่มหลังรอบแรกกี่รอบ (แต่ละรอบเดินก่อน 1 ครั้ง) อยากเร็วกลับเป็น 1
local walkMinPx    = 70     -- ระยะเดินต่ำสุดต่อก้าว (พิกเซลในจอเกม) ~ 2-3 ช่อง ปรับตามซูม
local walkMaxPx    = 110    -- ระยะเดินสูงสุดต่อก้าว
local walkCandidates = 12   -- สุ่มจุดเดินมากี่ตัวเลือก แล้วเลือกจุดที่ห่างจากที่ Greed ไปแล้วมากสุด
local leashPx      = 140    -- ไม่ให้เดินห่างจุดเริ่มเกินนี้ (พิกเซล) กันตัวละครหลุดออกนอกที่ของตก
local yScale       = 0.75   -- มุมกล้อง RO แกนตั้งถูกบีบ: ระยะแนวตั้งบนจอ = ระยะจริง x ค่านี้ (1 = ไม่บีบ)
local walkWaitBase = 600    -- รอหลังคลิกเดิน (ms) ส่วนคงที่
local walkWaitPerPx = 8     -- + ms ต่อพิกเซลที่เดิน (เดินไกลรอนานขึ้น เดินใกล้ไม่เสียเวลา)
local walkWaitJitter = 120  -- สุ่มเพิ่มเวลารออีกไม่เกินเท่านี้ (ms)
local walkClickHold = 40

-- รอหลัง Greed ในรอบที่ 2-3 (หลังเดิน)
local fastAfterGreed = 100

-- ===== ฟังก์ชัน 3: 6, F9, Enter, 5 (สลับชุด + เทเล) =====
-- กด F9 กี่ครั้ง (1 = ปกติ, 2 = กดสองครั้ง)
local f9Presses = 2
local f9RepeatGap = 300   -- รอระหว่าง F9 ครั้งที่ 1 กับครั้งที่ 2 (ms)
local func3Keys = { "6", "f9", "enter", "5" }
local func3Hold = 30
-- รอหลังกดแต่ละปุ่มของลำดับเทเล  { 6, F9, Enter, 5 }  (ต้องมีจำนวนเท่ากับ func3Keys)
-- ตำแหน่งที่ 2 (หลัง F9) = รอให้หน้าต่างเทเลขึ้นก่อนกด Enter ไม่งั้น Enter จะเปิดช่องแชท
-- ถ้า Enter ยังเปิดแชทอยู่ ให้เพิ่มค่าตำแหน่งที่ 2 ทีละ 200
local func3Gaps = { 100, 600, 400, 300 }

-- สร้างลำดับใหม่ตามจำนวนครั้งที่กด F9 (ครั้งก่อนสุดท้ายรอ f9RepeatGap, ครั้งสุดท้ายรอค่าเดิมของ F9)
if f9Presses > 1 then
    local keys, gaps = {}, {}
    for i, k in ipairs(func3Keys) do
        if k == "f9" then
            for n = 1, f9Presses do
                keys[#keys + 1] = "f9"
                gaps[#gaps + 1] = (n < f9Presses) and f9RepeatGap or func3Gaps[i]
            end
        else
            keys[#keys + 1] = k
            gaps[#gaps + 1] = func3Gaps[i]
        end
    end
    func3Keys, func3Gaps = keys, gaps
end
local func3After = 300   -- รอหลังจบลำดับเทเล ก่อนกลับไปกวาด

-- กด F5 ทุกรอบรูทีน (หลังขั้นตอนเทเล)
local afterTeleKeys = { "f5" }
local afterTeleHold = 30
local afterTeleGap  = 200   -- รอหลังกด F5

-- กด F6 ทุก 300 วินาที (ทำหลังเทเล + F5 ตอนครบเวลา)
local f6Interval = 300000   -- ms (300 วินาที)
local f6Hold = 40
local f6After = 200
local f6Delay = 500   -- รอหลังกด F5 ก่อนกด F6 (ms)
local lastF6Time = 0

-- กด F1 ทุก 10 นาที (ทำเฉพาะตอนไม่ได้ทำฟังก์ชัน 2/3)
local f1Interval = 300000   -- ms (10 นาที)
local f1Hold = 40
local f1After = 150

-- ===== การสุ่มกวาด =====
local jitter = 1.0          -- สุ่มขยับจุด (1.0 = ±ครึ่งช่อง, 0 = ปิด)
local centerChance = 0.5   -- โอกาสแทรกจุดใกล้กลางกรอบ (0-1)
local centerScale = 0.5     -- ขนาดโซนกลาง เทียบกับกรอบ (0.5 = ครึ่งหนึ่ง)

local lastStopTime = -10000

-- ===== ฟังก์ชันช่วย =====
local function clamp(v)
    if v < 0 then return 0 end
    if v > 65535 then return 65535 end
    return v
end

local widthUnits  = areaW * 65535 / (screenW - 1)
local heightUnits = areaH * 65535 / (screenH - 1)
local stepX = widthUnits / (gridSize - 1)
local stepY = heightUnits / (gridSize - 1)

-- ฟังก์ชัน 1: กด 1 แล้วคลิกซ้าย
local function pressOneAndClick()
    PressKey("1")
    Sleep(holdKey)
    ReleaseKey("1")
    Sleep(gapDelay)

    PressMouseButton(1)
    Sleep(holdClick)
    ReleaseMouseButton(1)
    Sleep(afterDelay)
end

-- เลื่อนเม้าไปจุดนั้นแล้วกด 1 + คลิก
local function visit(x, y)
    MoveMouseTo(clamp(math.floor(x)), clamp(math.floor(y)))
    Sleep(moveDelay)
    pressOneAndClick()
end

-- สร้างรายการจุดทั้งหมดแล้วสลับลำดับ
local function buildOrder()
    local list = {}
    for r = 0, gridSize - 1 do
        for c = 0, gridSize - 1 do
            list[#list + 1] = { r, c }
        end
    end
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

-- กดชุดปุ่ม (คืนค่า true ถ้าถูกกดปุ่ม 4 หยุดกลางทาง)
local function runKeys(keys, hold, gap)
    for _, k in ipairs(keys) do
        if IsMouseButtonPressed(4) then return true end
        PressKey(k)
        Sleep(hold)
        ReleaseKey(k)
        Sleep(gap)
    end
    return false
end

-- รอแบบเช็กปุ่ม 4 ไปด้วย (คืนค่า true ถ้าถูกกดหยุด)
local function waitOrStop(ms)
    local t = GetRunningTime()
    while GetRunningTime() - t < ms do
        if IsMouseButtonPressed(4) then return true end
        Sleep(20)
    end
    return false
end

-- กดชุดปุ่มโดยกำหนดช่วงรอแต่ละปุ่มแยกกัน
local function runKeysGaps(keys, hold, gaps)
    for i, k in ipairs(keys) do
        if IsMouseButtonPressed(4) then return true end
        PressKey(k)
        Sleep(hold)
        ReleaseKey(k)
        if waitOrStop(gaps[i] or gaps[#gaps]) then return true end
    end
    return false
end


-- รูทีน: รอของตก -> สลับชุด Greed -> กด Greed ซ้ำ -> สลับชุด + เทเล
-- (ระหว่างนี้ไม่กวาด ไม่กด 1 ไม่คลิก)
-- ===== เดินสุ่มแบบกระจาย =====
-- offset ทั้งหมดอยู่ในหน่วยพิกเซลจากจุดเริ่มรูทีน (ตัวละครอยู่กลางจอเสมอ = cx, cy)
local function dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- สุ่มหลายทิศ แล้วเลือกทิศที่จุดปลายทางห่างจากทุกจุดที่ Greed ไปแล้ว (รวมจุดเริ่ม) มากที่สุด
-- จุดที่ไกลจากจุดเริ่มเกิน leashPx จะถูกหักคะแนนหนัก (ยังเลือกได้ถ้าไม่มีทางเลือกอื่น)
local function pickWalk(posX, posY, visited)
    local bestDx, bestDy, bestScore = 0, 0, -1e12
    for _ = 1, walkCandidates do
        local a = math.random() * 2 * math.pi
        local d = walkMinPx + math.random() * (walkMaxPx - walkMinPx)
        local dx, dy = math.cos(a) * d, math.sin(a) * d
        local nx, ny = posX + dx, posY + dy
        local score = 1e12
        for _, v in ipairs(visited) do
            local s = dist2(nx, ny, v[1], v[2])
            if s < score then score = s end
        end
        if dist2(nx, ny, 0, 0) > leashPx * leashPx then
            score = score - 1e9
        end
        if score > bestScore then
            bestScore, bestDx, bestDy = score, dx, dy
        end
    end
    return bestDx, bestDy
end

-- คลิกเดินไปตาม offset (dx, dy) แล้วรอตามระยะทาง (คืนค่า true ถ้าถูกกดปุ่ม 4 หยุด)
local function walkBy(cx, cy, dx, dy)
    local sx = dx * 65535 / (screenW - 1)
    local sy = dy * yScale * 65535 / (screenH - 1)
    MoveMouseTo(clamp(math.floor(cx + sx)), clamp(math.floor(cy + sy)))
    Sleep(moveDelay)
    PressMouseButton(1)
    Sleep(walkClickHold)
    ReleaseMouseButton(1)
    local dist = math.sqrt(dx * dx + dy * dy)
    return waitOrStop(walkWaitBase + dist * walkWaitPerPx + math.random() * walkWaitJitter)
end

local function runRoutine(cx, cy)
    if enableFunc2 then
    -- 1) รอให้มอนตัวสุดท้ายตายและของตก
    if waitOrStop(dropWait) then return true end

    -- 2) สลับเป็นชุด Greed (Z) ครั้งเดียว แล้ว Greed รอบแรก (C) ตรงจุดที่ยืนอยู่
    if runKeys(swapToGreedKeys, swapHold, swapGap) then return true end
    if waitOrStop(swapSettle) then return true end
    if runKeys(greedKeys, greedHold, greedKeyGap) then return true end
    if waitOrStop(greedGap) then return true end

    -- 3) เดินแบบกระจาย แล้วกด C ซ้ำ ไม่กด Z และไม่กด X
    -- จำจุดที่ Greed ไปแล้ว แต่ละก้าวเลือกทิศที่ห่างจากจุดเก่าทั้งหมดมากที่สุด (ไม่เดินซ้ำที่เดิม)
    local posX, posY = 0, 0
    local visited = { { 0, 0 } }
    for i = 1, extraGreeds do
        local dx, dy = pickWalk(posX, posY, visited)
        if walkBy(cx, cy, dx, dy) then return true end
        posX, posY = posX + dx, posY + dy
        visited[#visited + 1] = { posX, posY }
        if runKeys(greedKeys, greedHold, greedKeyGap) then return true end
        if waitOrStop(fastAfterGreed) then return true end
    end

    -- 4) ครบทุกรอบแล้วค่อยสลับกลับ (X)
    if runKeys(swapBackKeys, swapHold, swapGap) then return true end
    if waitOrStop(swapBackSettle) then return true end
    end  -- จบฟังก์ชัน 2

    -- 5) สลับชุด + เทเล (ฟังก์ชัน 3)
    if enableFunc3 then
        if runKeysGaps(func3Keys, func3Hold, func3Gaps) then return true end
    end

    -- 6) กด F5 ทุกรอบรูทีน
    if enableF5 then
        if runKeys(afterTeleKeys, afterTeleHold, afterTeleGap) then return true end
    end

    -- 7) ครบ 300 วินาที กด F6 (หลัง F5)
    if enableF6 and GetRunningTime() - lastF6Time >= f6Interval then
        if waitOrStop(f6Delay) then return true end
        if runKeys({ "f6" }, f6Hold, f6After) then return true end
        lastF6Time = GetRunningTime()
    end

    if enableFunc3 and waitOrStop(func3After) then return true end
    return false
end

local function pressF1()
    PressKey("f1")
    Sleep(f1Hold)
    ReleaseKey("f1")
    Sleep(f1After)
end

-- กด F1, F5, F6 ครั้งแรกตอนเริ่ม (เฉพาะที่เปิดอยู่) คืนค่า true ถ้าถูกกดปุ่ม 4 หยุด
local function runStartupKeys()
    local list = {}
    if enableF1 then list[#list + 1] = { "f1", f1Hold } end
    if enableF5 then list[#list + 1] = { "f5", afterTeleHold } end
    if enableF6 then list[#list + 1] = { "f6", f6Hold } end
    for _, item in ipairs(list) do
        if IsMouseButtonPressed(4) then return true end
        PressKey(item[1])
        Sleep(item[2])
        ReleaseKey(item[1])
        if waitOrStop(startKeysGap) then return true end
    end
    return false
end

-- ===== ตัวหลัก: กดปุ่ม 4 เพื่อเริ่ม/หยุด =====
function OnEvent(event, arg)
    if event == "MOUSE_BUTTON_PRESSED" and arg == 4 then
        -- ทิ้ง event ที่เข้ามาไม่นานหลังหยุด (event ค้างคิว/ซ้ำ)
        if GetRunningTime() - lastStopTime < 1000 then
            return
        end

        while IsMouseButtonPressed(4) do Sleep(10) end
        Sleep(150)

        math.randomseed(GetRunningTime())
        math.random(); math.random()

        -- ตำแหน่งเม้าตอนกดเริ่ม = ศูนย์กลางพื้นที่กวาด
        local startX, startY = GetMousePosition()
        local originX = startX - widthUnits / 2
        local originY = startY - heightUnits / 2
        -- กด F1, F5, F6 ครั้งแรก แล้วค่อยเริ่มนับเวลารอบถัดไป
        local stop = runStartupKeys()
        local lastRoutineTime = GetRunningTime()
        local lastF1Time = GetRunningTime()
        lastF6Time = GetRunningTime()

        while not stop do
            local order = buildOrder()
            for _, p in ipairs(order) do
                if IsMouseButtonPressed(4) then
                    stop = true
                    break
                end

                -- ครบเวลา -> หยุดกวาด ทำรูทีน Greed + เทเล แล้วค่อยกวาดต่อ
                if GetRunningTime() - lastRoutineTime >= routineInterval then
                    if runRoutine(startX, startY) then
                        stop = true
                        break
                    end
                    lastRoutineTime = GetRunningTime()
                end

                -- ครบ 10 นาที -> กด F1 (ไม่ทำถ้ารูทีนเพิ่งจบ หรือใกล้ถึงเวลาทำ
                -- เพื่อไม่ให้ชนกัน ไว้เลื่อนไปจุดถัดไป)
                local now = GetRunningTime()
                if enableF1 and now - lastF1Time >= f1Interval
                   and now - lastRoutineTime > 1500
                   and routineInterval - (now - lastRoutineTime) > 3000 then
                    pressF1()
                    lastF1Time = GetRunningTime()
                end

                -- จุดตามตาราง + สุ่มขยับเล็กน้อย
                local jx = (math.random() - 0.5) * stepX * jitter
                local jy = (math.random() - 0.5) * stepY * jitter
                if enableFunc1 then
                    visit(originX + p[2] * stepX + jx,
                          originY + p[1] * stepY + jy)

                    -- แทรกจุดสุ่มใกล้กลางกรอบ
                    if math.random() < centerChance then
                        visit(startX + (math.random() - 0.5) * widthUnits * centerScale,
                              startY + (math.random() - 0.5) * heightUnits * centerScale)
                    end
                else
                    Sleep(50)   -- ปิดกวาด: รอเฉยๆ ให้ตัวจับเวลาทำงานต่อ
                end
            end
        end

        MoveMouseTo(startX, startY)
        while IsMouseButtonPressed(4) do Sleep(10) end
        lastStopTime = GetRunningTime()
    end
end
