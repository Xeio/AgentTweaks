import com.GameInterface.DistributedValue;
import com.GameInterface.AgentSystemAgent;
import com.GameInterface.AgentSystemMission;
import com.GameInterface.AgentSystem;
import com.Utils.Archive;
import mx.utils.Delegate;


class com.xeio.AgentTweaks.AgentTweaks
{    
    private var m_swfRoot: MovieClip;

    private var m_uiScale:DistributedValue;
    
    private var m_baseFillMissions:Function;
    
    private var m_timeout:Number;

    public static function main(swfRoot:MovieClip):Void 
    {
        var AgentTweaks = new AgentTweaks(swfRoot);

        swfRoot.onLoad = function() { AgentTweaks.OnLoad(); };
        swfRoot.OnUnload =  function() { AgentTweaks.OnUnload(); };
        swfRoot.OnModuleActivated = function(config:Archive) { AgentTweaks.Activate(config); };
        swfRoot.OnModuleDeactivated = function() { return AgentTweaks.Deactivate(); };
    }

    public function AgentTweaks(swfRoot: MovieClip) 
    {
        m_swfRoot = swfRoot;
    }

    public function OnUnload()
    {
        m_uiScale.SignalChanged.Disconnect(SetUIScale, this);
        m_uiScale = undefined;
    }

    public function Activate(config: Archive)
    {
    }

    public function Deactivate(): Archive
    {
        var archive: Archive = new Archive();			
        return archive;
    }
	
	public function OnLoad()
	{
        m_uiScale = DistributedValue.Create("AgentTweaks_UIScale");
        m_uiScale.SignalChanged.Connect(SetUIScale, this);
        
        InitializeUI();
	}
    
    public function SetUIScale()
    {
        _root.agentsystem._xscale = m_uiScale.GetValue();
        _root.agentsystem._yscale = m_uiScale.GetValue();
    }
    
    private function InitializeUI()
    {
        var content = _root.agentsystem.m_Window.m_Content;
        
        if (!content.m_Roster || !content.m_MissionList)
        {
            setTimeout(Delegate.create(this, InitializeUI), 100);
            return;
        }
        
        SetUIScale();
        
        content.m_MissionList.SignalEmptyMissionSelected.Connect(SlotEmptyMissionSelected, this);
        
        content.m_Roster.SignalAgentSelected.Connect(SlotAgentSelected, this);
        
        InitializeAvailableMissionsListUI();
    }
    
    private function SlotEmptyMissionSelected()
    {
        m_baseFillMissions = undefined;
        
        setTimeout(Delegate.create(this, InitializeAvailableMissionsListUI), 100);
    }
    
    private function InitializeAvailableMissionsListUI()
    {
        var availableMissionList = _root.agentsystem.m_Window.m_Content.m_AvailableMissionList;
        
        if (!availableMissionList)
        {
            setTimeout(Delegate.create(this, InitializeAvailableMissionsListUI), 100);
            return;
        }
        
        m_baseFillMissions = Delegate.create(availableMissionList, availableMissionList.FillMissions);
        availableMissionList.FillMissions = Delegate.create(this, FillMissionsOverride);
        
        FillMissionsOverride();
    }
    
    private function FillMissionsOverride()
    {
        var availableMissionList = _root.agentsystem.m_Window.m_Content.m_AvailableMissionList;
        
        if (!availableMissionList)
        {
            return;
        }
        
        m_baseFillMissions();
        
        var agent:AgentSystemAgent = _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet.m_AgentData;
                
        for(var i:Number = 0; i < 5; i++)
        {
            var slot:String = "m_Slot_" + i;
            var agentIcon = availableMissionList[slot].m_AgentIcon;
            var missionData:AgentSystemMission = availableMissionList[slot].m_MissionData;
            
            if (agent && missionData && missionData.m_MissionId > 0)
            {
                var successChance:Number = AgentSystem.GetSuccessChanceForAgent(agent.m_AgentId, missionData.m_MissionId);
                agentIcon._visible = true;
                agentIcon.m_Success._visible = true;
                agentIcon.m_Success.m_Text.text = successChance + "%";
            }
            else
            {
                agentIcon.m_Success._visible = false;
            }
            
            if (missionData && missionData.m_MissionId > 0)
            {                
                var hours = String(Math.floor(missionData.m_ActiveDuration / 60 / 60));
                if (hours.length == 1) hours = "0" + hours;
                var minutes = String((missionData.m_ActiveDuration / 60) % 60);
                if (minutes.length == 1) minutes = "0" + minutes;
                
                agentIcon.m_Timer._visible = true;
                agentIcon.m_Timer.text = hours + ":" + minutes;
            }
            else
            {
                agentIcon.m_Timer._visible = false;
            }
            
            agentIcon._visible = agentIcon.m_Timer._visible || agentIcon.m_Success._visible;
        }
    }
    
    private function SlotAgentSelected()
    {
        FillMissionsOverride();
        _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet.SignalClose.Connect(FillMissionsOverride, this);
    }
}