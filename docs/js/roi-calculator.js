// ROI Calculator Functionality
document.addEventListener('DOMContentLoaded', function() {
    // Input elements
    const modelsPerYear = document.getElementById('models-per-year');
    const dsSalary = document.getElementById('ds-salary');
    const teamSize = document.getElementById('team-size');
    const timeToBuild = document.getElementById('time-to-build');
    
    // Result elements
    const totalSavings = document.getElementById('total-savings');
    const hiringSavings = document.getElementById('hiring-savings');
    const productivitySavings = document.getElementById('productivity-savings');
    const roiPercentage = document.getElementById('roi-percentage');
    const paybackPeriod = document.getElementById('payback-period');
    
    // ProspectML cost (annual)
    const PROSPECTML_ANNUAL_COST = 12000; // $1000/month
    
    // Calculate ROI
    function calculateROI() {
        // Get input values
        const models = parseInt(modelsPerYear.value) || 12;
        const salary = parseInt(dsSalary.value) || 180000;
        const team = parseInt(teamSize.value) || 2;
        const weeks = parseInt(timeToBuild.value) || 4;
        
        // Calculate total compensation (salary + 40% for benefits, taxes, etc.)
        const totalComp = salary * 1.4;
        
        // Calculate current cost
        const weeksPerYear = 52;
        const projectsPerPersonPerYear = weeksPerYear / weeks;
        const peopleNeeded = Math.ceil(models / projectsPerPersonPerYear);
        
        // Hiring savings: How many data scientists you don't need to hire
        const peopleAvoided = Math.max(0, peopleNeeded - team);
        const hiringSavingsValue = peopleAvoided * totalComp;
        
        // Productivity savings: Value from accelerated model development
        const timeReduction = 0.75; // 75% time reduction with ProspectML
        
        // Calculate the value of time saved
        // Even if you don't need more people, you're getting models 4x faster
        const timeValue = team * totalComp * 0.5; // 50% of team cost represents time value
        
        // Calculate opportunity cost - faster models mean faster business value
        const projectsCurrentlyHandled = Math.min(models, team * projectsPerPersonPerYear);
        const accelerationValue = projectsCurrentlyHandled * (totalComp / projectsPerPersonPerYear) * 0.3; // 30% opportunity value
        
        // Total productivity gains
        const productivityGains = timeValue + accelerationValue;
        
        // Total savings
        const totalSavingsValue = hiringSavingsValue + productivityGains - PROSPECTML_ANNUAL_COST;
        
        // ROI calculation
        const roi = ((totalSavingsValue / PROSPECTML_ANNUAL_COST) * 100).toFixed(0);
        
        // Payback period
        const monthlyBenefit = totalSavingsValue / 12;
        const monthlyProspectMLCost = PROSPECTML_ANNUAL_COST / 12;
        const paybackMonths = monthlyProspectMLCost / Math.max(monthlyBenefit, 1);
        const paybackWeeks = Math.ceil(paybackMonths * 4.33);
        
        // Update display
        totalSavings.textContent = '$' + formatNumber(Math.round(totalSavingsValue));
        hiringSavings.textContent = '$' + formatNumber(Math.round(hiringSavingsValue));
        productivitySavings.textContent = '$' + formatNumber(Math.round(productivityGains));
        roiPercentage.textContent = formatNumber(roi) + '%';
        
        if (paybackWeeks < 4) {
            paybackPeriod.textContent = Math.ceil(paybackWeeks) + ' week' + (paybackWeeks > 1 ? 's' : '');
        } else if (paybackMonths < 12) {
            paybackPeriod.textContent = Math.ceil(paybackMonths) + ' month' + (paybackMonths > 1 ? 's' : '');
        } else {
            paybackPeriod.textContent = 'Immediate';
        }
        
        // Add color coding based on savings
        if (totalSavingsValue > 500000) {
            totalSavings.style.color = '#059669'; // Green
        } else if (totalSavingsValue > 200000) {
            totalSavings.style.color = '#10b981'; // Light green
        } else if (totalSavingsValue > 0) {
            totalSavings.style.color = '#1a56db'; // Blue
        } else {
            totalSavings.style.color = '#ef4444'; // Red
        }
    }
    
    // Format number with commas
    function formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }
    
    // Add event listeners
    if (modelsPerYear && dsSalary && teamSize && timeToBuild) {
        modelsPerYear.addEventListener('input', calculateROI);
        dsSalary.addEventListener('input', calculateROI);
        teamSize.addEventListener('input', calculateROI);
        timeToBuild.addEventListener('input', calculateROI);
        
        // Initial calculation
        calculateROI();
    }
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
});