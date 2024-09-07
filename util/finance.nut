function BankBalance()
{
    /*
    * Returns the current bank balance of the AI company.
    */
    return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
}

function HasMoney(amount)
{
    /*
    * Returns true if the AI company has enough money (or load) to pay the given amount.
    */
    return (BankBalance() + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) > amount) ? true : false;
}

function GetMoney(amount)
{
    /*
    * Withdraws the given amount from the AI company's bank account.
    */
    Info("Need amount " + amount + " we have " + BankBalance() + " ( " + (BankBalance()*100/amount) + "% )");
	if (!HasMoney(amount) || BankBalance() > amount) { return }

    // Loan excess money
	local loan = amount - BankBalance() + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan -= loan % AICompany.GetLoanInterval();

    Warning("Loaning " + loan + " of loan " + AICompany.GetMaxLoanAmount() + " ( " + (loan*100/AICompany.GetMaxLoanAmount()) + "% )")
	AICompany.SetLoanAmount(loan);
}

function RepayLoan()
{
    /*
    * Repays as much of the loan as possible whilst keeping a reserve.
    */
    if (BankBalance() > RESERVE_MONEY + AICompany.GetLoanInterval() && AICompany.GetLoanAmount() > 0) {
        // Repay as much of the loan as we can whilst keeping a reserve
        local payment = (BankBalance() - RESERVE_MONEY) % AICompany.GetLoanInterval();
        payment = BankBalance() - RESERVE_MONEY - payment
        local newLoan = AICompany.GetLoanAmount() - payment
        AICompany.SetLoanAmount(newLoan<0?0:newLoan);
        Info("Repaying " + payment + " of loan " + AICompany.GetMaxLoanAmount() + " ( " + (payment*100/AICompany.GetMaxLoanAmount()) + "% )")
    }
}

function MaximumBudget()
{
    return AICompany.GetMaxLoanAmount() - RESERVE_MONEY; // TODO: the reserve should be an inflation adjusted value
}

function CurrentFunds()
{
    return BankBalance() + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount())
}