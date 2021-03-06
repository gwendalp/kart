function subscriber_cmd_vel_callback(msg)
   -- This is the subscriber callback function when receiving /cmd_vel  topic
   -- The msg is a Lua table defining linear and angular velocities
   --   linear velocity along x = msg["linear"]["x"]
   --   linear velocity along y = msg["linear"]["y"]
   --   linear velocity along z = msg["linear"]["z"]
   --   angular velocity along x = msg["angular"]["x"]
   --   angular velocity along y = msg["angular"]["y"]
   --   angular velocity along z = msg["angular"]["z"]
   spdLin = msg["linear"]["x"]
   servoPos = msg["angular"]["z"]
   kLin = 2
   kAng = -0.2 
   spdLin = kLin*spdLin
   servoPos = kAng*servoPos
   sim.setJointTargetVelocity(Motor, spdLin)
   --sim.setJointTargetVelocity(SteeringBarRight,spdRight)
   sim.setJointTargetPosition(SteeringLeft,servoPos)
   sim.addStatusbarMessage('cmd_vel subscriber receiver : spdLin ='..spdLin..',servoPos='..servoPos..'')
end
 
function getPose(objectName)
   -- This function get the object pose at ROS format geometry_msgs/Pose
   objectHandle=sim.getObjectHandle(objectName)
   relTo = -1
   p=sim.getObjectPosition(objectHandle,relTo)
   o=sim.getObjectQuaternion(objectHandle,relTo)
   return {
      position={x=p[1],y=p[2],z=p[3]},
      orientation={x=o[1],y=o[2],z=o[3],w=o[4]}
   }
end
 
function getTransformStamped(objHandle,name,relTo,relToName)
   -- This function retrieves the stamped transform for a specific object
   t=sim.getSystemTime()
   p=sim.getObjectPosition(objHandle,relTo)
   o=sim.getObjectQuaternion(objHandle,relTo)
   return {
      header={
	 stamp=t,
	 frame_id=relToName
      },
      child_frame_id=name,
      transform={
	 translation={x=p[1],y=p[2],z=p[3]},
	 rotation={x=o[1],y=o[2],z=o[3],w=o[4]}
      }
   }
end
 
function sysCall_init()
   -- The child script initialization
   objectName="Chassis"
   objectHandle=sim.getObjectHandle(objectName)
   -- get left and right motors handles
   Motor = sim.getObjectHandle("RearAxis")
   --rightSteering = sim.getObjectHandle("SteeringBarRight")
   SteeringLeft = sim.getObjectHandle("SteeringLeft")
   rosInterfacePresent=simROS
   -- Prepare the publishers and subscribers :
   if rosInterfacePresent then
      publisher1=simROS.advertise('/simulationTime','std_msgs/Float32')
      publisher2=simROS.advertise('/pose','geometry_msgs/Pose')
      subscriber1=simROS.subscribe('/cmd_vel','geometry_msgs/Twist','subscriber_cmd_vel_callback')
   end
end
 
function sysCall_actuation()
   -- Send an updated simulation time message, and send the transform of the object attached to this script:
   if rosInterfacePresent then
      -- publish time and pose topics
      simROS.publish(publisher1,{data=sim.getSimulationTime()})
      simROS.publish(publisher2,getPose("Chassis"))
      -- send a TF
      simROS.sendTransform(getTransformStamped(objectHandle,objectName,-1,'world'))
      -- To send several transforms at once, use simROS.sendTransforms instead
   end
end
 
function sysCall_cleanup()
    -- Following not really needed in a simulation script (i.e. automatically shut down at simulation end):
    if rosInterfacePresent then
        simROS.shutdownPublisher(publisher1)
        simROS.shutdownPublisher(publisher2)
        simROS.shutdownSubscriber(subscriber1)
    end
end
