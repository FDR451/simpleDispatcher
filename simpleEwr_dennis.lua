--[[
    simpleEwr v0.0.1 Lightweight simple EWR script

    todo:
        eventhandler to remove destroyed targets from the knownTargets table
        autmatic clean up of targets that have not been seen for x minutes, not sure if it is either worth it or useful

]]

simpleEwr = {}
simpleEwr.ewrUnitList = {} --{"EWR-1", "EWR-2"}
simpleEwr.knownTargets = {} --table of known targets
simpleEwr.clockTiming = 6 --tiem between checks, lower interval higher workload
simpleEwr.detectionZone = false --false until set
simpleEwr.detectionFlag = false --false until set
simpleEwr.debug = false

--main functions

function simpleEwr.debugNotify(message) --used this so often now... 
    if simpleEwr.debug == true then
        trigger.action.outText(tostring(message), 5)
    end
end

function simpleEwr.start() --starts simpleEWR
end

function simpleEwr.stop()
end

function simpleEwr.addEwrByPrefix (prefix) --later, look at skynet how it is done
end

function simpleEwr.addEwrByName (unitName) --adds an EWR to the ewrUnitList by it's unit name
end

function simpleEwr.addEwrByTable (table) --adds EWRs as a table ie: table = {"EWR-1", "EWR-2", "EWR-n"}
    simpleEwr.ewrUnitList = table
end

function simpleEwr.setUpdateInterval (seconds) --sets the interval for the repeated detection check
    simpleEwr.clockTiming = seconds
end

function simpleEwr.setDetectionFlag (flagNumber) --sets the flag that should be used after a detection event
    simpleEwr.detectionFlag = flagNumber
end

function simpleEwr.setDetectionZone (groupName)
    simpleEwr.detectionZone = mist.getGroupPoints(groupName)
end

function simpleEwr.getKnownTargets() -- returns the table of known targets, might be useful for the dispatcher
    return simpleEwr.knownTargets
end

function simpleEwr.ewrDetectTargets () --iterates through the table of EWRs and checks if they detect something, if they detect an aircraft it gets handed off to
    for k, vEwrUnit in pairs (simpleEwr.ewrUnitList) do
        local _targets = Unit.getByName(vEwrUnit):getController():getDetectedTargets(Controller.Detection.Radar)
        if _targets then
            for i = 1, #_targets do

                if _targets[i].object and _targets[i].distance == true then

                    local _object = _targets[i].object

                    if _object:getCoalition() == 2 then

                        local args = {
                            objectId = _object.id_,
                            unitName = _object:getName(),
                            unitPosVec3 = _object:getPoint(),
                            unitVelVec3 = _object:getVelocity(),
                            detectionTime = timer.getTime(),
                            inZone = simpleEwr.isVecInZone(_object:getPoint()),

                            --probalby not saved here, no reason to run the calculation every time a target is detected. Just run it once it is needed for the intercept based on the last known position and heading
                            unitSpeed = mist.vec.mag(_object:getVelocity()), --speed in m/s
                            unitHeading = math.atan2 (_object:getVelocity().x, _object:getVelocity().z), 
                        }

                        simpleEwr.knownTargets[args.objectId] = args
                    end
                end
            end
        end
    end
end

function simpleEwr.decider() --checks if a detected target is inside of the detection zone
    for index, vTargetTable in pairs (simpleEwr.knownTargets) do
        --if vTargetTable.unitPosVec3 and simpleEwr.isVecInZone(vTargetTable.unitPosVec3) then
        if vTargetTable.inZone == true then

            --vTargetTable.inZone = true

            simpleEwr.debugNotify("positive detection!")
            simpleEwr.applyFlag()
           
        else
            --vTargetTable.inZone = false
            simpleEwr.debugNotify("negative detection!")
        end
    end
end

function simpleEwr.isVecInZone(vec3) --returns true if a vec3 is in the detection zone
    if simpleEwr.detectionZone ~= false then --zone exists / has been defined
        if mist.pointInPolygon(vec3 ,  simpleEwr.detectionZone) then
            simpleEwr.debugNotify("in zone")
            return true
        else
            simpleEwr.debugNotify("not in zone")
            return false
        end
    else
        simpleEwr.debugNotify("no zone defined")
        return true --no idea, but it feels better than false...
    end
end

function simpleEwr.applyFlag () --sets the flag to be used with the mission editor
    if simpleEwr.detectionFlag ~= false then
        trigger.action.setUserFlag(simpleEwr.detectionFlag, true )
    end
end

function simpleEwr.readKnownTargets() --debugging...
    simpleEwr.debugNotify("_____________known targets____________")
    for k, v in pairs (simpleEwr.knownTargets) do
        simpleEwr.debugNotify("k: " .. tostring(k) .. " v: " .. tostring(v))
        for k2, v2 in pairs (v) do
            simpleEwr.debugNotify("____k2: " .. tostring(k2) .. " v2: " .. tostring(v2))
        end
    end
end

function simpleEwr.getEwrDebugTargets () --purely for debugging
    for k, vUnit in pairs (simpleEwr.ewrUnitList) do

        simpleEwr.debugNotify("k: " .. k .. "; vUnit: " .. vUnit)

        local _targets = Unit.getByName(vUnit):getController():getDetectedTargets(Controller.Detection.Radar)

        if _targets then
            for k2, v2 in pairs (_targets) do
                simpleEwr.debugNotify("____k2: " .. tostring(k2) .. "; v2: " .. tostring(v2) )
                for k3, v3 in pairs (v2) do
                    simpleEwr.debugNotify ("________k3: " .. tostring(k3) .. "; v3: " .. tostring(v3) )

                    if type(v3) == "table" then 
                        for k4, v4 in pairs (v3) do
                            simpleEwr.debugNotify ("____________k4: " .. tostring(k4) .. "; v4: " .. tostring(v4) )

                            local _id = v3.id_
                            local _obj = v3
                            simpleEwr.debugNotify ("ID: " .. _id)
                            local _name = _obj:getName()
                            local _unit = Unit.getByName(_name)
                            local _point = _unit:getPoint()
                            simpleEwr.debugNotify("vec3.x: " .. _point.x .. " vec3.y: " .. _point.y) 
                            simpleEwr.debugNotify ("name: " .. _name)

                            --local _name = simpleEwr.getUnitNameById(_id)
                            --simpleEwr.debugNotify("Name: " .. _name)

                        end
                    end
                end
            end
        end
    end
end

function simpleEwr.repeater ()
    simpleEwr.debugNotify ("tick")

    simpleEwr.ewrDetectTargets()
    simpleEwr.decider()

    --simpleEwr.readKnownTargets()

    simpleEwr.debugNotify ("tock")
end

do  
    local repeater = mist.scheduleFunction (simpleEwr.repeater, {}, timer.getTime() + 2, simpleEwr.clockTiming )

    --player input functions, should be set in ME or other file, but here for testing

    simpleEwr.debugNotify("simpleEwr finished loading")
end