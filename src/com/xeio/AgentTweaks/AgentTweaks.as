import com.Components.InventoryItemList.MCLItemIconCellRenderer;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.AgentSystemAgent;
import com.GameInterface.AgentSystemMission;
import com.GameInterface.AgentSystem;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.Utils.Archive;
import com.xeio.AgentTweaks.Utils;
import com.Utils.LDBFormat;
import mx.utils.Delegate;
import com.GameInterface.LoreBase;

class com.xeio.AgentTweaks.AgentTweaks
{    
    private var m_swfRoot: MovieClip;

    private var m_uiScale:DistributedValue;
    
    private var m_timeout:Number;
    
    static var GEAR_BAG:String = LDBFormat.LDBGetText(50200, 9405788);
    static var HEIGHT:Number = 20;
    
    var m_baseFillMissions:Function;

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
        AgentSystem.SignalAgentStatusUpdated.Disconnect(AgentStatusUpdated, this);
        m_uiScale.SignalChanged.Disconnect(SetUIScale, this);        
        m_uiScale = undefined;
        //In the off chance it's just this add-on unloading, close the whole agent system too so our events don't break things
        DistributedValueBase.SetDValue("agentSystem_window", false);
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
        
        AgentSystem.SignalAgentStatusUpdated.Connect(AgentStatusUpdated, this);
        
        InitializeUI();
	}
    
    private function AgentStatusUpdated(agentData:AgentSystemAgent)
    {
        if (_root.agentsystem.m_Window.m_Content.m_AgentInfoSheet.m_AgentData.m_AgentId == agentData.m_AgentId)
        {
            UpdateMissionsDisplay();
            UpdateAgentDisplay(agentData);
        }
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
        
        setTimeout(Delegate.create(this, InitializeAvailableMissionsListUI), 100);
        
        var inventoryPanel : MovieClip = content.m_InventoryPanel;
        var removeAllButton = inventoryPanel.attachMovie("Final claim Reward States", "u_unequipAll", inventoryPanel.getNextHighestDepth());
        removeAllButton._y -= 15;
        removeAllButton._width = 160
        removeAllButton.textField.text = "Get All Items";
        removeAllButton.disableFocus = true
        removeAllButton.addEventListener("click",this,"UnequipAll");
    }
    
    private function SlotEmptyMissionSelected()
    {
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
        
        if (!availableMissionList.u_fillMissionsOverriden)
        {
            m_baseFillMissions = Delegate.create(availableMissionList, availableMissionList.FillMissions);
            m_baseFillMissions.FillMissions = Delegate.create(this, FillMissionsOverride);
            availableMissionList.u_fillMissionsOverriden = true;
            
            availableMissionList.m_ButtonBar.addEventListener("change", this, "UpdateMissionsDisplay");
        }
        
        UpdateMissionsDisplay();
    }
    
    private function FillMissionsOverride()
    {
        if (!_root.agentsystem.m_Window.m_Content.m_AvailableMissionList)
        {
            m_baseFillMissions = undefined;
            return;
        }
        
        m_baseFillMissions();
        
        UpdateMissionsDisplay();
    }
    
    private function UpdateMissionsDisplay()
    {
        var availableMissionList = _root.agentsystem.m_Window.m_Content.m_AvailableMissionList;
        
        if (!availableMissionList)
        {
            return;
        }
                
        var agent:AgentSystemAgent = _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet.m_AgentData;
                
        for(var i:Number = 0; i < 5; i++)
        {
            var slotId:String = "m_Slot_" + i;
            var slot:MovieClip = availableMissionList[slotId];
            
            var agentIcon = slot.m_AgentIcon;
            var missionData:AgentSystemMission = slot.m_MissionData;
            var bonusView = slot.m_BonusView;
            
            if (agent && missionData && missionData.m_MissionId > 0)
            {
                var successChance:Number = AgentSystem.GetSuccessChanceForAgent(agent.m_AgentId, missionData.m_MissionId);
                agentIcon._visible = true;
                agentIcon.m_Success._visible = true;
                agentIcon.m_Success.m_Text.text = successChance + "%";
                
                if (BonusIsMatch(agent, missionData))
                {
                    bonusView.m_Header.textColor = 0x00FF00
                }
                else
                {
                    bonusView.m_Header.textColor = 0xFFFFFF
                }
            }
            else
            {
                agentIcon.m_Success._visible = false;
                bonusView.m_Header.textColor = 0xFFFFFF
            }
            
            for (var j = 0; j <= 10; j++)
            {
                //Clear any items if they exist
                slot["u_customItems" + j].removeMovieClip();
            }
            if (!slot.u_bonusText && slot.m_Timer)
            {
                var m_Timer:TextField = slot.m_Timer;
                var bonusText = slot.createTextField("u_bonusText", slot.getNextHighestDepth(), 0, slot.m_ActiveBG._height - 15, 100, 20);
                bonusText.setNewTextFormat(m_Timer.getTextFormat());
                bonusText.text = "Bonuses";
                bonusText.embedFonts = true;
            }
            
            if (missionData && missionData.m_MissionId > 0)
            {
                var hours = String(Math.floor(missionData.m_ActiveDuration / 60 / 60));
                if (hours.length == 1) hours = "0" + hours;
                var minutes = String((missionData.m_ActiveDuration / 60) % 60);
                if (minutes.length == 1) minutes = "0" + minutes;
                
                agentIcon.m_Timer._visible = true;
                agentIcon.m_Timer.text = hours + ":" + minutes;
                
                var customItemCount = 0;
                var normal = 0;
                var bonus = 0;
                for (var r in missionData.m_Rewards)
                {
                    var item:InventoryItem = Inventory.CreateACGItemFromTemplate(missionData.m_Rewards[r], 0, 0, 1);
                    if(IsImportant(item))
                    {
                        var newItem = slot.attachMovie("IconSlot", "u_customItems" + customItemCount, slot.getNextHighestDepth());
                        newItem._height = newItem._width = HEIGHT;
                        newItem._y = slot.m_ActiveBG._height - newItem._height - 5;
                        newItem._x = 120 + (HEIGHT + 5) * normal;
                        var itemslot = new _global.com.Components.ItemSlot(undefined, 0, newItem);
                        itemslot.SetData(item);
                        
                        customItemCount++;
                        normal++;
                    }
                }
                for (var r in missionData.m_BonusRewards)
                {
                    var item:InventoryItem = Inventory.CreateACGItemFromTemplate(missionData.m_BonusRewards[r], 0, 0, 1);
                    if(IsImportant(item))
                    {
                        var newItem = slot.attachMovie("IconSlot", "u_customItems" + customItemCount, slot.getNextHighestDepth());
                        newItem._height = newItem._width = HEIGHT;
                        newItem._y = slot.m_ActiveBG._height - HEIGHT - 5;
                        newItem._x = 390 - (HEIGHT + 5) * bonus;
                        var itemslot = new _global.com.Components.ItemSlot(undefined, 0, newItem);
                        itemslot.SetData(item);
                        
                        customItemCount++;
                        bonus++;
                    }
                }
                if (bonus > 0)
                {
                    slot.u_bonusText._x = 390 - (HEIGHT + 5) * bonus - 50;
                    slot.u_bonusText._visible = true;
                }
                else
                {
                    slot.u_bonusText._visible = false;
                }
            }
            else
            {
                agentIcon.m_Timer._visible = false;
                slot.u_bonusText._visible = false;
            }
            
            agentIcon._visible = agentIcon.m_Timer._visible || agentIcon.m_Success._visible;
        }
    }
    
    private function SlotAgentSelected()
    {
        UpdateMissionsDisplay();
        _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet.SignalClose.Connect(UpdateMissionsDisplay, this);
        UpdateAgentDisplay()
    }
    
    private function UpdateAgentDisplay(agent:AgentSystemAgent)
    {
        var agentInfoSheet :MovieClip = _root.agentsystem.m_Window.m_Content.m_AgentInfoSheet;
        if (!agentInfoSheet)
        {
            return;
        }
        
        if (!agent)
        {
            agent = agentInfoSheet.m_AgentData;
        }
        
        var healthField : TextField = agentInfoSheet.u_health;
        if (!AgentSystem.IsAgentFatigued(agent.m_AgentId))
        {
            if (!healthField)
            {
                var m_Timer : TextField = agentInfoSheet.m_Timer;
                healthField = agentInfoSheet.createTextField("u_health", agentInfoSheet.getNextHighestDepth(), m_Timer._x, m_Timer._y, m_Timer._width, m_Timer._height)
                healthField.setNewTextFormat(m_Timer.getTextFormat())
                healthField.embedFonts = true
            }
            
            healthField._visible = true;
            healthField.text = "Fatigue: " + (100 - agent.m_FatiguePercent) + "%";
        }
        else
        {
            healthField._visible = false;
        }
    }
    
    private function UnequipAll()
    {
        var agents = AgentSystem.GetAgents();
        for (var i in agents)
        {
            var agent:AgentSystemAgent = agents[i];
            if (!AgentSystem.IsAgentOnMission(agent.m_AgentId))
            {
                if(AgentSystem.GetItemOnAgent(agent.m_AgentId).m_Name)
                {
                    var agentInventory:Inventory = new Inventory(new com.Utils.ID32(_global.Enums.InvType.e_Type_GC_AgentEquipmentInventory, Character.GetClientCharID().GetInstance()));
                    var firstFree:Number = agentInventory.GetFirstFreeItemSlot();
                    if (firstFree != -1)
                    {
                        AgentSystem.UnequipItemOnAgent(agent.m_AgentId, agentInventory.GetInventoryID(), firstFree);
                        setTimeout(Delegate.create(this, UnequipAll), 200)
                        return;
                    }
                    else 
                    {
                        break;
                    }
                }
            }
        }
    }
    
    private function BonusIsMatch(agent:AgentSystemAgent, mission:AgentSystemMission) : Boolean
    {
        if (!mission.m_BonusTraitCategories || mission.m_BonusTraitCategories.length == 0)
        {
            return false;
        }
        
        var agentOverrides = AgentSystem.GetAgentOverride(agent.m_AgentId);
        
        for (var i in mission.m_BonusTraitCategories)
        {
            var bonusTrait = mission.m_BonusTraitCategories[i];
            if (bonusTrait != agent.m_Trait1Category && bonusTrait != agent.m_Trait2Category && bonusTrait != agentOverrides[3])
            {
                return false;
            }
        }
        
        return true;
    }
    
    private function IsImportant(item:InventoryItem)
    {
        if (item.m_Name.indexOf("stillat") != -1 && (item.m_Name.indexOf("cc)") != -1 || item.m_Name.indexOf("cm3)") != -1))
        {
            //Distillates
            return false;
        }
        if (item.m_Name.indexOf("Anima Shards") != -1 || item.m_Name.indexOf("Anima-Splitter") != -1 || item.m_Name.indexOf("Anima-Splitter") != -1)
        {
            //Anima shards
            return false;
        }
        
        //Any uncategorized items are important (known items like Dossiers and Gear bags)
        return true;
    }
}