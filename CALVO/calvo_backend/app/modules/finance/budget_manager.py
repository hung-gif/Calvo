# File: app/modules/finance/budget_manager.py
# Purpose: Logic to determine if a transaction violates budget thresholds.
# Language: English

class BudgetManager:
    # Hardcoded thresholds for now (Future: Load from User Settings DB)
    ALERT_THRESHOLD_ABSOLUTE_VND = 5000000.0  # 5 Million VND
    ALERT_THRESHOLD_PERCENT = 0.20            # 20% of current balance

    @staticmethod
    def check_over_budget(amount_in_account_currency: float, current_balance: float) -> bool:
        """
        Determines if a withdrawal is risky.
        Returns True if alert should be triggered.
        """
        # Rule 1: Absolute Amount Check
        if amount_in_account_currency >= BudgetManager.ALERT_THRESHOLD_ABSOLUTE_VND:
            return True
            
        # Rule 2: Percentage Check
        # Only check if balance is positive to avoid division by zero
        if current_balance > 0:
            spending_ratio = amount_in_account_currency / current_balance
            if spending_ratio >= BudgetManager.ALERT_THRESHOLD_PERCENT:
                return True
                
        return False