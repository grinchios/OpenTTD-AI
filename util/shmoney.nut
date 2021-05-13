function BankBalance() {
    // Check the AI bank balance
    return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
}

function HasMoney(amount) {
    // Check if we have enough money (via loan and on bank).
    return (BankBalance() + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) > amount) ? true : false;
}

function GetMoney(amount) {
    // Get the amount of money requested, loan if needed.
    Info("Need amount " + amount + " we have " + BankBalance() + " ( " + (BankBalance()*100/amount) + "% )");

	if (!HasMoney(amount) || BankBalance() > amount) return;

    // Loan excess money
	local loan = amount - BankBalance() + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan -= loan % AICompany.GetLoanInterval();
    
    Warning("Loaning " + loan + " of loan " + AICompany.GetMaxLoanAmount() + " ( " + (loan*100/AICompany.GetMaxLoanAmount()) + "% )")
	AICompany.SetLoanAmount(loan);
}

function RepayLoan() {
    if (BankBalance() > RESERVE_MONEY + AICompany.GetLoanInterval() && AICompany.GetLoanAmount() > 0) {
        // Repay as much of the loan as we can whilst keeping a reserve
        local payment = (BankBalance() - RESERVE_MONEY) % AICompany.GetLoanInterval();
        payment = BankBalance() - RESERVE_MONEY - payment
        local newLoan = AICompany.GetLoanAmount() - payment
        AICompany.SetLoanAmount(newLoan<0?0:newLoan);
        Info("Repaying " + payment + " of loan " + AICompany.GetMaxLoanAmount() + " ( " + (payment*100/AICompany.GetMaxLoanAmount()) + "% )")
    }
}

function MaximumBudget() {
    return AICompany.GetMaxLoanAmount() - RESERVE_MONEY;
}

function CurrentFunds() {
    return BankBalance() + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount())
}