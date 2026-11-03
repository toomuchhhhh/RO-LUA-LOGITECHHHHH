-- ===== ตั้งค่าพื้นที่กวาด =====
-- ขนาดจอมอนิเตอร์จริง (ใช้แปลงพิกเซลเป็นหน่วย G HUB)
local screenW, screenH = 2560, 1440

-- ขนาดหน้าต่างเกม (Window Mode)
local gameW, gameH = 1024, 768

-- พื้นที่กวาดเป็น % ของหน้าต่างเกม ศูนย์กลางคือตำแหน่งเม้าตอนกดปุ่ม 4
-- ลดเหลือ 14 ให้ของตกอยู่ในรัศมี Greed (5x5) เป็นส่วนใหญ่ (เดิม 27.3)
local areaWPercent = 14
local areaHPercent = 14

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
local routineInterval = 5000  -- ทุกกี่ ms เริ่มรูทีน Greed + เทเล (5000, 10000-15000 ปกติ)

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
local extraGreeds  = 0      -- Greed เพิ่มหลังรอบแรกกี่รอบ (แต่ละรอบเดินก่อน 1 ครั้ง)
local walkMinPx    = 70    -- ระยะเดินต่ำสุด (พิกเซลในจอเกม) ~ 2-3 ช่อง ปรับตามซูม
local walkMaxPx    = 110    -- ระยะเดินสูงสุด
local walkWait     = 1400   -- รอให้ตัวละครเดินถึงและหยุดนิ่งก่อนกด Greed (เดิม 900 สั้นไป)
local walkClickHold = 40
local turnDeg      = 90     -- รอบถัดไปเลี้ยวจากทิศเดิมกี่องศา (90 = เดินเป็นตัว L ไม่วนกลับจุดเดิม)

-- รอหลัง Greed ในรอบที่ 2-3 (หลังเดิน)
local fastAfterGreed = 100

-- ===== ฟังก์ชัน 3: 6, F9, Enter, 5 (สลับชุด + เทเล) =====
local func3Keys = { "6", "f9", "enter", "5" }
local func3Hold = 30
-- รอหลังกดแต่ละปุ่มของลำดับเทเล  { 6, F9, Enter, 5 }  (ต้องมีจำนวนเท่ากับ func3Keys)
-- ตำแหน่งที่ 2 (หลัง F9) = รอให้หน้าต่างเทเลขึ้นก่อนกด Enter ไม่งั้น Enter จะเปิดช่องแชท
-- ถ้า Enter ยังเปิดแชทอยู่ ให้เพิ่มค่าตำแหน่งที่ 2 ทีละ 200
local func3Gaps = { 250, 700, 400, 300 }
local func3After = 300   -- รอหลังจบลำดับเทเล ก่อนกลับไปกวาด

-- กด F1 ทุก 10 นาที (ทำเฉพาะตอนไม่ได้ทำฟังก์ชัน 2/3)
local f1Interval = 600000   -- ms (10 นาที)
local f1Hold = 40
local f1After = 150

-- ===== การสุ่มกวาด =====
local jitter = 1.0          -- สุ่มขยับจุด (1.0 = ±ครึ่งช่อง, 0 = ปิด)
local centerChance = 0.35   -- โอกาสแทรกจุดใกล้กลางกรอบ (0-1)
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
-- คลิกเดินไปทิศสุ่ม (ตัวละครอยู่กลางจอ = ตำแหน่งเม้าตอนกดเริ่ม)
local function walkRandom(cx, cy, angle)
    local distPx = walkMinPx + math.random() * (walkMaxPx - walkMinPx)
    local dx = math.cos(angle) * distPx * 65535 / (screenW - 1)
    local dy = math.sin(angle) * distPx * 65535 / (screenH - 1)
    MoveMouseTo(clamp(math.floor(cx + dx)), clamp(math.floor(cy + dy)))
    Sleep(moveDelay)
    PressMouseButton(1)
    Sleep(walkClickHold)
    ReleaseMouseButton(1)
    return waitOrStop(walkWait)
end

local function runRoutine(cx, cy)
    -- 1) รอให้มอนตัวสุดท้ายตายและของตก
    if waitOrStop(dropWait) then return true end

    -- 2) สลับเป็นชุด Greed (Z) ครั้งเดียว แล้ว Greed รอบแรก (C) ตรงจุดที่ยืนอยู่
    if runKeys(swapToGreedKeys, swapHold, swapGap) then return true end
    if waitOrStop(swapSettle) then return true end
    if runKeys(greedKeys, greedHold, greedKeyGap) then return true end
    if waitOrStop(greedGap) then return true end

    -- 3) เดินสุ่มทิศ แล้วกด C ซ้ำ ไม่กด Z และไม่กด X
    -- ตัวละครเดินสะสมจากจุดล่าสุด จึงต้องเลี้ยวต่อจากทิศเดิม (ไม่ใช้ทิศตรงข้าม เพราะจะเดินกลับจุดเดิม)
    -- มุมแรกสุ่ม รอบถัดไปเลี้ยว ±turnDeg จากทิศก่อนหน้า (สุ่มซ้าย/ขวา)
    local angle = math.random() * 2 * math.pi
    for i = 1, extraGreeds do
        if i > 1 then
            local sign = (math.random() < 0.5) and -1 or 1
            angle = angle + sign * math.rad(turnDeg)
        end
        if walkRandom(cx, cy, angle) then return true end
        if runKeys(greedKeys, greedHold, greedKeyGap) then return true end
        if waitOrStop(fastAfterGreed) then return true end
    end

    -- 4) ครบทุกรอบแล้วค่อยสลับกลับ (X)
    if runKeys(swapBackKeys, swapHold, swapGap) then return true end
    if waitOrStop(swapBackSettle) then return true end

    -- 5) สลับชุด + เทเล
    if runKeysGaps(func3Keys, func3Hold, func3Gaps) then return true end
    if waitOrStop(func3After) then return true end
    return false
end

local function pressF1()
    PressKey("f1")
    Sleep(f1Hold)
    ReleaseKey("f1")
    Sleep(f1After)
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
        local stop = false
        local lastRoutineTime = GetRunningTime()
        local lastF1Time = GetRunningTime()

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
                if now - lastF1Time >= f1Interval
                   and now - lastRoutineTime > 1500
                   and routineInterval - (now - lastRoutineTime) > 3000 then
                    pressF1()
                    lastF1Time = GetRunningTime()
                end

                -- จุดตามตาราง + สุ่มขยับเล็กน้อย
                local jx = (math.random() - 0.5) * stepX * jitter
                local jy = (math.random() - 0.5) * stepY * jitter
                visit(originX + p[2] * stepX + jx,
                      originY + p[1] * stepY + jy)

                -- แทรกจุดสุ่มใกล้กลางกรอบ
                if math.random() < centerChance then
                    visit(startX + (math.random() - 0.5) * widthUnits * centerScale,
                          startY + (math.random() - 0.5) * heightUnits * centerScale)
                end
            end
        end

        MoveMouseTo(startX, startY)
        while IsMouseButtonPressed(4) do Sleep(10) end
        lastStopTime = GetRunningTime()
    end
end