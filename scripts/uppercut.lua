
-- local inspect = require("inspect")
-- local log = require("log")
-- log.level = "warn"
local img = "effects/shotup_fireball.png"
-- delay if no target under?

Prime_Uppercut = Skill:new{
	Class = "Brute",
	Icon = "weapons/prime_shift.png",
	Rarity = 1,
	Shield = 0,
	Damage = 2,
    -- Push = false,
	CollisionDamage = 0,
	FriendlyDamage = true,
	Cost = "low",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {3,2},
	Range = 1, --TOOLTIP INFO
	LaunchSound = "/weapons/shift",
	TipImage = StandardTips.Melee,
}
Prime_Uppercut_A = Prime_Uppercut:new{
    Damage = 3,
    -- Push = true
}
Prime_Uppercut_B = Prime_Uppercut:new{
    CollisionDamage = 3
}
Prime_Uppercut_AB = Prime_Uppercut:new{
    -- Push = true,
    Damage = 3,
    CollisionDamage = 3
}

function Prime_Uppercut:GetSkillEffect(p1, p2)
    local result = SkillEffect()

    local punch = SpaceDamage(p2)
    -- punch.sAnimation = "explopunch1_"..GetDirection(p2-p1)
    punch.sSound = "/props/satellite_launch"
    result:AddMelee(p1, punch, NO_DELAY)
    result:AddBoardShake(2)
    result:AddDelay(1)

    local pawn = Board:GetPawn(p2)
    if pawn and not pawn:IsGuarding() then
        result:AddScript("Prime_Uppercut.DoItAt(" .. p2:GetString() .. ", " .. tostring(self.Damage) .. ", " .. tostring(self.CollisionDamage) .. ")")

        result:AddDelay(0.125)
        -- if self.Push then
        --     local fakearr = SpaceDamage(p2, DAMAGE_ZERO)
        --     local str_dirs = {"up","right","down","left"}
        --     for i = DIR_START, DIR_END do
        --         fakearr.loc = p2 + DIR_VECTORS[i]
        --         if Prime_Uppercut.DoesPushCollide(p2, i) then
        --             fakearr.sImageMark = "combat/arrow_hit_"..str_dirs[i+1]..".png"
        --         else
        --             fakearr.sImageMark = "combat/arrow_"..str_dirs[i+1]..".png"
        --         end
        --         result:AddDamage(fakearr)
        --     end
        -- end
    end
    result:AddDamage(SpaceDamage(p2, self.Damage))

    return result
end

function Prime_Uppercut.DoesPushCollide(p0, dir)
    local dirv = DIR_VECTORS[dir]
    local p = p0 + dirv
    local p_next = p + dirv
    local pawn = Board:GetPawn(p)
    return pawn and Board:IsBlocked(p_next, pawn:GetPathProf()) and not pawn:IsGuarding()
end
function Prime_Uppercut:GetTargetArea(point)
	return Board:GetSimpleReachable(point, 1, self.CornersAllowed)
end

function Prime_Uppercut.RestoreAfterPunch(state)
    local pawn = Board:GetPawn(state.Id)
    if pawn then
        pawn:SetInvisible(false)
        pawn:SetSpace(state.Space)
        if not pawn:IsDead() then
            pawn:SpawnAnimation()
        end
    end
end

function GetEffect(state)
    local eff = SkillEffect()
    eff.piOrigin = Point(-10-state.Space.y,-10-state.Space.x)
    local dam = SpaceDamage(state.Space, DAMAGE_DEATH)
    eff:AddSound("/props/satellite_launch")

    eff:AddBoardShake(1.1)
    eff:AddArtillery(dam, img)
    eff:AddDelay(0.1)
    for i = -2, 2 do
        for j = -2, 2 do
            local cur = state.Space + Point(i,j)
            local strength = math.max(4 - state.Space:Manhattan(cur), 0) * 3
            if strength > 0 then
                eff:AddBounce(cur, strength)
            end
        end
    end
    eff:AddEmitter(state.Space, "Emitter_Unit_Crashed")
    eff:AddBoardShake(1)
    eff:AddScript("Prime_Uppercut.RestoreAfterPunch("..save_table(state)..")")
    -- if state.DoPush then
    --     local push = SpaceDamage()
    --     for dir = DIR_START, DIR_END do
    --         push.loc = state.Space + DIR_VECTORS[dir]
    --         push.sAnimation = "airpush_"..dir
    --         push.iPush = dir
    --         eff:AddDamage(push)
    --     end
    -- end
    local extra = Board:IsBlocked(state.Space, state.PathProf) and state.CollisionDamage or 0
    dam = SpaceDamage(state.Space, extra+state.Damage)
    dam.sAnimation = "explo_fire1"
    if extra > 0 then
        dam.sScript = "Board:AddAlert("..state.Space:GetString()..", \"ALERT_COLLISION\")"
    end
    eff:AddDamage(dam)
    return eff
end

function Prime_Uppercut.DoItAt(p, damage, extradamage)
    local pawn = Board:GetPawn(p)


    local launcheff = SkillEffect()
    launcheff.piOrigin = p

    -- local launchprep = SpaceDamage(p)
    -- launchprep.sScript = "Board:StartShake(1)"
    -- -- launchprep.sSound = "/props/satellite_launch"
    -- launchprep.fDelay = 0.75
    -- -- launchprep.sAnimation = "SmokeBack"
    -- launcheff:AddDamage(launchprep)
    local visual = SpaceDamage(p)
    visual.sAnimation = "explo_fire1"
    launcheff:AddDamage(visual)
    -- visual.sAnimation = "SmokeBack"
    -- for dir = DIR_START, DIR_END do
    --     visual.loc = p + DIR_VECTORS[dir]
    --     launcheff:AddDamage(visual)
    -- end
    launcheff:AddScript( "Prime_Uppercut.HideUnit("..p:GetString()..")")

    local state = Prime_Uppercut.MkState("combat/tile_icon/tile_lightning.png", "lightning", p, damage, extradamage, pawn:GetPathProf(), pawn:GetId())
    launcheff:AddScript("Prime_Uppercut.QueueEvent("..save_table(state)..")")

    local liftoff = SpaceDamage(Point(-1-p.y, -1-p.x))
    liftoff.sSound = "/props/pod_incoming"
    launcheff:AddAnimation(p, "splash_3")
    -- launcheff:AddBounce(p, 5)
    -- launcheff:AddEmitter(p, "Emitter_Missile")
    launcheff:AddArtillery(liftoff, img)

    Board:AddEffect(launcheff)
end

function Prime_Uppercut.HideUnit(p)
    local pawn = Board:GetPawn(p)
    pawn:SetSpace(Point(32,32))
    pawn:SetActive(false)
    pawn:SetInvisible(true)
    pawn:ClearQueued()
end

local PendingEvents = { }
local CurrentAttack = nil

local function PushLocal(env)
    if not env.Injected then
        env.Injected = {}
    end
    for _, v in ipairs(PendingEvents) do
        env.Injected[#env.Injected+1] = v
    end
    PendingEvents = {}
end
local function IsEffect(env)
    PushLocal(env)
    return env.Injected and #env.Injected > 0
end
local function ApplyEffect(env)
    PushLocal(env)
    if IsEffect(env) then
        CurrentAttack = env.Injected[1]
        table.remove(env.Injected,1)
        local effect = GetEffect(CurrentAttack)
        Board:AddEffect(effect)
        return IsEffect(env)
    else
        return false
    end
end
local function MarkBoard(env)
    PushLocal(env)
	if (#env.Injected == 0) and not Board:IsBusy() then 
		CurrentAttack = nil
	end
		
	for _,v in ipairs(env.Injected) do
        Board:MarkSpaceDesc(v.Space,v.Desc)
	    if CurrentAttack == v then
            Board:MarkSpaceImage(v.Space,v.CombatIcon, GL_Color(255,150,150,0.75))
        else
            Board:MarkSpaceImage(v.Space,v.CombatIcon, GL_Color(255,226,88,0.75))
	    end
	end
end

local appenv_base = Mission.ApplyEnvironmentEffect
function Mission:ApplyEnvironmentEffect()
    return ApplyEffect(self.LiveEnvironment) or appenv_base(self)
end

local isenv_base = Mission.IsEnvironmentEffect
function Mission:IsEnvironmentEffect()
    return isenv_base(self) or IsEffect(self.LiveEnvironment)
end
local baseupdate_base = Mission.BaseUpdate
function Mission:BaseUpdate()
    baseupdate_base(self)
    MarkBoard(self.LiveEnvironment)
end
-- local planenv_base = Mission.PlanEnvironment
function ResetUppercut(env)
    -- planenv_base(self)
    if env then
        env.Injected = {}
    end
    PendingEvents = {}
end

function Prime_Uppercut.QueueEvent(effect)
    PendingEvents[#PendingEvents+1] = effect
end
function Prime_Uppercut.MkState(CombatIcon, Desc, Space, Damage, CollisionDamage, PathProf, Id)
    return {
        CombatIcon = CombatIcon,
        Desc = Desc,
        Space = Space,
        Damage = Damage,
        CollisionDamage = CollisionDamage,
        Id = Id,
        PathProf = PathProf
    }
end
