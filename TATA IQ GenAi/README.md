# TATA IQ GenAI Data Analytics Job sitmulation (Forage)

📊 Credit Card Delinquency Risk Analysis
      This project simulates a real-world financial risk analytics task to identify customers likely to become delinquent and translate insights into       actionable business strategies.

🎯 Objective:
      Analyze customer financial & behavioral data
      Identify key risk drivers of delinquency
      Build a predictive ML model
      Provide business recommendations backed by data
      Ensure ethical and responsible AI use

🔎 Exploratory Data Analysis (EDA)
      EDA was conducted to understand data quality, structure, and risk patterns.

    Key findings:
      Overall delinquency rate: ~16%
    Higher risk among:
            Business credit card holders
            Customers with multiple recent missed/late payments
            Unemployed customers
            Monthly payment flags were inconsistent, so a new feature was engineered:
            Total_Missed_Late_Payments — strongest behavioral risk indicator. 

    EDA_SummaryReport contains all the findings 

🤖 Predictive Model
Model Used: LightGBM (Gradient Boosting) + SMOTE
Why:
    Handles non-linear financial patterns
    Works well with imbalanced data
    Commonly used in credit risk modeling
    The model outputs a probability of delinquency for proactive risk management. 

  Tata IQ ModelPlan_ further expands on this.

📏 Evaluation Focus
Because delinquency is rare but costly, priority was given to:
  Recall (catching high-risk customers)
  F1 Score
  ROC-AUC
  Confusion Matrix analysis

💼 Business Recommendation

    High-risk segment: Business credit card customers

    Action Plan:
      Early engagement at 30 days past due via reminders + optional financial support.
    
    Success Metrics:
      15% reduction in delinquency
      10% increase in on-time payments (6 months)
    This shifts collections from reactive recovery → proactive prevention. 

Business_Summary_Report has all the details.
Presentation_Tata_genAi summarises the findings and recommendations for stakeholders
tataiq_codes is a python notebook with the codes used.

🧩 Tools Used

Python • Pandas • Scikit-learn • LightGBM • SMOTE • GenAI (for assisted EDA summaries)
