class Mungo extends AIController
{
  constructor()
  {
  } 
}

/**
* Check if we have enough money (via loan and on bank).
*/
function Mungo::HasMoney(money)
{
if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) > money) return true;
return false;
}

/**
 * Get the amount of money requested, loan if needed.
 */
function Mungo::GetMoney(money)
{
	if (!this.HasMoney(money)) return;
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > money) return;

	local loan = money - AICompany.GetBankBalance(AICompany.COMPANY_SELF) + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan = loan - loan % AICompany.GetLoanInterval();
	AILog.Info("Need a loan to get " + money + ": " + loan);
	AICompany.SetLoanAmount(loan);
}

function Mungo::Start()
{
  AILog.Info("Mungo Started.");
  SetCompanyName();

  //set a legal railtype. 
  local types = AIRailTypeList();
  AIRail.SetCurrentRailType(types.Begin());
      
  //Keep running. If Start() exits, the AI dies.
  while (true) {
    this.Sleep(100);
    AILog.Warning("TODO: Add functionality to the AI.");
  }
}

function Mungo::Save()
{
  local table = {};	
  //TODO: Add your save data to the table.
  return table;
}

function Mungo::Load(version, data)
{
  AILog.Info(" Loaded");
  //TODO: Add your loading routines.
}


function Mungo::SetCompanyName()
{
  if(!AICompany.SetName("Mungo")) {
    local i = 2;
    while(!AICompany.SetName("Mungo #" + i)) {
      i = i + 1;
      if(i > 255) break;
    }
  }
  AICompany.SetPresidentName("P. Resident");
}