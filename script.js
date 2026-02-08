async function initDashboard() {
    try {
        const response = await fetch('./data.json');
        if (!response.ok) throw new Error("Could not fetch data.json");
        const data = await response.json();

        // 1. Update Metadata
        document.getElementById('last-updated').innerText = 
            `Last Updated: ${data.metadata.updated_at} | Latest Games: ${data.metadata.latest_game_date}`;

        // 2. Render Daily Chart (Bar)
        const dailyCtx = document.getElementById('dailyChart').getContext('2d');
        new Chart(dailyCtx, {
            type: 'bar',
            data: {
                labels: data.daily_leaders.map(p => p.athlete_display_name),
                datasets: [{
                    label: 'Points Scored',
                    data: data.daily_leaders.map(p => p.points),
                    backgroundColor: '#3b82f6',
                    borderRadius: 4
                }]
            },
            options: {
                responsive: true,
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true, title: { display: true, text: 'Points' } } }
            }
        });

        // 3. Render Season Chart (Scatter)
        const scatterCtx = document.getElementById('scatterChart').getContext('2d');
        
        // Prepare scatter data format: { x: rpg, y: ppg, player: name }
        const scatterData = data.season_leaders.map(p => ({
            x: p.rpg,
            y: p.ppg,
            player: p.athlete_display_name,
            team: p.team_short_display_name
        }));

        new Chart(scatterCtx, {
            type: 'scatter',
            data: {
                datasets: [{
                    label: 'Player Stats',
                    data: scatterData,
                    backgroundColor: 'rgba(255, 99, 132, 0.6)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    pointRadius: 6,
                    pointHoverRadius: 8
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const p = context.raw;
                                return `${p.player} (${p.team}): ${p.y} PPG, ${p.x} RPG`;
                            }
                        }
                    }
                },
                scales: {
                    x: { title: { display: true, text: 'Rebounds Per Game (RPG)' } },
                    y: { title: { display: true, text: 'Points Per Game (PPG)' } }
                }
            }
        });

    } catch (error) {
        console.error(error);
        document.getElementById('last-updated').innerText = "Error loading data. Please check console.";
    }
}

initDashboard();