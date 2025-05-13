 

const ResultsDisplay = () => {
  console.log("ResultsDisplay component rendering");
  
  const [results, setResults] = React.useState({
    presentationAward: {
      teams: []
    },
    implementationAward: {
      teams: []
    }
  });

  const [currentView, setCurrentView] = React.useState('overview');
  const [showConfetti, setShowConfetti] = React.useState(false);
  const [animateResults, setAnimateResults] = React.useState(false);
  const [liveData, setLiveData] = React.useState(null);
  const [showWinner, setShowWinner] = React.useState(false);
  const [winnerRevealed, setWinnerRevealed] = React.useState(false);
  const [showResults, setShowResults] = React.useState(false);
  const [loadingError, setLoadingError] = React.useState('');
  const audioRef = React.useRef(null);
  const socketRef = React.useRef(null);

  React.useEffect(() => {
    console.log("ResultsDisplay: useEffect running");
    // Connect to the Socket.IO server
    try {
      socketRef.current = io();
      console.log("Socket.IO connected");
      
      // Listen for live voting updates
      socketRef.current.on('voting_update', (data) => {
        console.log("Received voting update:", data);
        setLiveData(data.votes);
      });
      
      // Listen for results updates
      socketRef.current.on('results_update', (data) => {
        console.log("Received results update:", data);
        setResults(data.results);
      });
      
      // Set up error handling for socket connection
      socketRef.current.on('connect_error', (error) => {
        console.error("Socket connection error:", error);
        setLoadingError(`Socket connection error: ${error.message}`);
      });
    } catch (error) {
      console.error("Error setting up socket:", error);
      setLoadingError(`Socket setup error: ${error.message}`);
    }
    
    // Initialize audio for winner announcement
    try {
      audioRef.current = new Audio('https://assets.mixkit.co/active_storage/sfx/944/944-preview.mp3');
    } catch (error) {
      console.warn("Audio setup error:", error);
      // Non-critical, so don't set error state
    }
    
    // Fetch initial data
    console.log("Fetching initial voting status data");
    fetch('/api/voting-status')
      .then(response => {
        console.log("Got response:", response.status);
        if (!response.ok) {
          throw new Error(`Server returned ${response.status}: ${response.statusText}`);
        }
        return response.json();
      })
      .then(data => {
        console.log("Received initial data:", data);
        if (data.votes) {
          setLiveData(data.votes);
        }
        if (data.results) {
          setResults(data.results);
        }
      })
      .catch(error => {
        console.error("Error fetching initial data:", error);
        setLoadingError(`データ取得エラー: ${error.message}`);
      });
    
    return () => {
      // Disconnect socket when component unmounts
      if (socketRef.current) {
        socketRef.current.disconnect();
        console.log("Socket disconnected");
      }
    };
  }, []);

  React.useEffect(() => {
    if (currentView === 'overview') {
      setAnimateResults(false);
    } else {
      setTimeout(() => setAnimateResults(true), 500);
    }
  }, [currentView]);

  const showAwards = () => {
    setShowConfetti(true);
    setShowWinner(true);
    
    // Play sound effect when showing winner
    if (audioRef.current) {
      audioRef.current.play().catch(e => console.log("Audio playback prevented by browser", e));
    }
    
    // Animate winner reveal
    setTimeout(() => {
      setWinnerRevealed(true);
    }, 2000);
    
    // Notify server about award ceremony
    if (socketRef.current) {
      socketRef.current.emit('award_ceremony_started');
    }
  };

  // Get ranked teams for both categories
  const getRankedTeams = (category) => {
    if (!results || !results[category] || !results[category].teams || results[category].teams.length === 0) {
      console.log(`No teams found for ${category}`);
      return [];
    }
    
    console.log(`Found ${results[category].teams.length} teams for ${category}`);
    
    // Sort teams by average score
    const sortedTeams = [...results[category].teams].sort((a, b) => b.average - a.average);
    
    // Add ranking
    return sortedTeams.map((team, index) => ({
      ...team,
      rank: index + 1
    }));
  };

  // Debug log
  console.log("Current results state:", results);

  const rankedPresentationTeams = getRankedTeams('presentationAward');
  const rankedImplementationTeams = getRankedTeams('implementationAward');

  console.log("Ranked presentation teams:", rankedPresentationTeams);
  console.log("Ranked implementation teams:", rankedImplementationTeams);

  // Calculate overall winner (combines both presentation and implementation scores)
  const calculateOverallWinner = () => {
    if (rankedPresentationTeams.length === 0 || rankedImplementationTeams.length === 0) {
      console.log("Not enough teams for overall winner");
      return null;
    }
    
    const teamScores = {};
    
    // Initialize team scores with presentation scores
    rankedPresentationTeams.forEach(team => {
      teamScores[team.id] = {
        id: team.id,
        name: team.name,
        members: team.members || [],
        comment: team.comment || '',
        presentationScore: team.average,
        implementationScore: 0,
        totalScore: team.average * 0.5, // 50% weight for presentation
      };
    });
    
    // Add implementation scores
    rankedImplementationTeams.forEach(team => {
      if (teamScores[team.id]) {
        teamScores[team.id].implementationScore = team.average;
        teamScores[team.id].totalScore += team.average * 0.5; // 50% weight for implementation
      }
    });
    
    // Convert to array and sort
    const sortedTeams = Object.values(teamScores).sort((a, b) => b.totalScore - a.totalScore);
    
    console.log("Overall winner calculation:", sortedTeams);
    
    return sortedTeams.length > 0 ? sortedTeams[0] : null; // Return the winner
  };

  const overallWinner = calculateOverallWinner();
  console.log("Overall winner:", overallWinner);

  // If there's a loading error, display it
  if (loadingError) {
    return (
      <div className="p-6 bg-red-50 border border-red-300 rounded-lg text-red-800">
        <h2 className="text-xl font-bold mb-2">エラーが発生しました</h2>
        <p>{loadingError}</p>
        <button 
          className="mt-4 px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
          onClick={() => window.location.reload()}
        >
          再読み込み
        </button>
      </div>
    );
  }

const renderOverview = () => (
  <div className="text-center">
    {liveData && (
      <div className="mb-10 flex flex-col min-h-[70vh] justify-between">
        <h3 className="text-2xl font-semibold mb-4 text-gray-800">ライブ投票状況</h3>
        <div className="flex justify-center gap-6">
          {Object.keys(liveData).map(teamId => {
            const teamNum = teamId.replace('team', '');
            const votes = liveData[teamId].voteCount || 0;
            
            return (
              <div key={teamId} className="bg-white rounded-xl shadow-md overflow-hidden border border-gray-200 w-48 h-48 transform hover:scale-105 transition-all duration-300">
                <div className="bg-gradient-to-r from-gray-800 to-gray-900 text-white p-2 text-center">
                  <h4 className="font-bold text-lg">チーム {teamNum}</h4>
                </div>
                
                <div className="p-6 text-center">
                  <div className="text-5xl font-bold text-gray-800">{votes}</div>
                  <div className="text-s text-gray-500 mt-4">投票数</div>
                </div>
              </div>
            );
          })}
        </div>
        
        <div className="mt-10 flex justify-center">
          <button
            onClick={() => setShowResults(!showResults)}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-all shadow"
          >
            {showResults ? (
              <>
                <span>結果を隠す</span>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M6 9l6 6 6-6" />
                </svg>
              </>
            ) : (
              <>
                <span>結果を表示</span>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 15l-6-6-6 6" />
                </svg>
              </>
            )}
          </button>
        </div>
      </div>
    )}
    
    {showResults && (
      <>
        <h2 className="text-3xl font-bold mb-8 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
          ハッカソン結果
        </h2>

<div className="grid grid-cols-1 md:grid-cols-2 gap-8">
  {/* プレゼン力賞 */}
  <button 
    onClick={() => setCurrentView('presentation')}
    className="p-10 rounded-xl bg-gradient-to-br from-indigo-600 to-indigo-800 text-white shadow-lg hover:shadow-xl transition-all transform hover:scale-105 duration-300 flex flex-col items-center justify-center relative overflow-hidden group"
  >
    <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
    <div className="absolute -top-20 -right-20 w-40 h-40 bg-indigo-400 rounded-full opacity-20"></div>

    {window.lucide && window.lucide.Award ? (
      <window.lucide.Award size={128} className="mb-3 drop-shadow-lg" />
    ) : (
      <div className="text-10xl mb-3">🏆</div>
    )}

    <h3 className="text-lg font-semibold mb-1">プレゼン力賞</h3>
    <p className="text-sm text-indigo-100">プレゼンテーションスキル</p>
  </button>

  {/* 実装力賞 */}
  <button 
    onClick={() => setCurrentView('implementation')}
    className="p-10 rounded-xl bg-gradient-to-br from-purple-600 to-pink-700 text-white shadow-lg hover:shadow-xl transition-all transform hover:scale-105 duration-300 flex flex-col items-center justify-center relative overflow-hidden group"
  >
    <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
    <div className="absolute -top-20 -right-20 w-40 h-40 bg-pink-300 rounded-full opacity-20"></div>

    {window.lucide && window.lucide.Code ? (
      <window.lucide.Code size={128} className="mb-3 drop-shadow-lg" />
    ) : (
      <div className="text-10xl mb-3">💻</div>
    )}

    <h3 className="text-lg font-semibold mb-1">実装力賞</h3>
    <p className="text-sm text-pink-100">実装の質</p>
  </button>
</div>


        {/* 最終結果を発表 Button */}
        <button 
          onClick={showAwards}
          className="mt-12 px-8 py-4 bg-gradient-to-r from-yellow-400 to-yellow-600 hover:from-yellow-500 hover:to-yellow-700 text-white rounded-lg shadow-lg hover:shadow-xl flex items-center justify-center mx-auto transition-all transform hover:scale-105 duration-300 font-bold text-lg"
          disabled={!overallWinner}
        >
          {window.lucide && window.lucide.Trophy ? (
            <window.lucide.Trophy size={28} className="mr-3" />
          ) : (
            <span className="mr-3 text-2xl">🏆</span>
          )}
          最終結果を発表
        </button>
      </>
    )}
  </div>
);

const renderDetailedResults = (category, teams, title, subtitle, gradientColors) => {
  console.log(`Rendering detailed results for ${category} with ${teams.length} teams`);

  if (teams.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">結果はまだありません。投票が完了するのを待ってください。</p>
        <button 
          onClick={() => setCurrentView('overview')}
          className="mt-4 px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg inline-flex items-center transition-all hover:translate-x-1"
        >
          {window.lucide?.ChevronRight ? (
            <window.lucide.ChevronRight className="rotate-180 mr-1" size={16} />
          ) : (
            <span className="mr-1">←</span>
          )}
          戻る
        </button>
      </div>
    );
  }

  return (
    <div>
      <button 
        onClick={() => setCurrentView('overview')}
        className="mb-6 px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg inline-flex items-center transition-all hover:translate-x-1"
      >
        {window.lucide?.ChevronRight ? (
          <window.lucide.ChevronRight className="rotate-180 mr-1" size={16} />
        ) : (
          <span className="mr-1">←</span>
        )}
        戻る
      </button>

      <h2 className={`text-3xl font-bold mb-2 bg-gradient-to-r ${gradientColors} bg-clip-text text-transparent`}>
        {title}
      </h2>
      <p className="text-gray-600 mb-8">{subtitle}</p>

      <div className="space-y-8">
        {teams.map((team) => {
          const isWinner = team.rank === 1;

          const cardWrapperClasses = `
            rounded-xl shadow-xl overflow-hidden transform transition-all duration-500 bg-white border
            ${isWinner ? 'border-yellow-400 scale-[1.02] shadow-2xl' : 'border-gray-200'}
            ${animateResults ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}
          `;

          const headerBgGradient = isWinner
            ? 'from-yellow-300 to-yellow-500'
            : category === 'presentation'
            ? 'from-indigo-400 to-indigo-600'
            : 'from-purple-500 to-purple-700';

          const barColor =
            isWinner ? 'bg-yellow-400'
            : category === 'presentation' ? 'bg-indigo-500'
            : 'bg-purple-500';

          return (
            <div key={team.id} className={cardWrapperClasses} style={{ transitionDelay: `${team.rank * 150}ms` }}>
              {/* Header */}
              <div className={`px-6 py-4 bg-gradient-to-r ${headerBgGradient} text-white`}>
                <div className="flex justify-between items-center">
                  <div className="flex items-center">
                    {isWinner && (
                      <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center mr-3 shadow-md">
                        {window.lucide?.Crown ? (
                          <window.lucide.Crown size={24} className="text-yellow-500" />
                        ) : (
                          <span className="text-lg">👑</span>
                        )}
                      </div>
                    )}
                    <h3 className="text-2xl font-bold tracking-wide">
                      {team.rank}位: {team.name}
                    </h3>
                  </div>
                  <div className="text-right text-white">
                    <div className="text-sm">スコア</div>
                    <div className="text-xl font-semibold">{team.average.toFixed(2)}</div>
                    <div className="text-xs opacity-80">({team.votes} 票)</div>
                  </div>
                </div>
              </div>

              {/* Body */}
              <div className="px-6 py-6">
                {/* Members */}
                <div className="flex items-start mb-5">
                  {window.lucide?.Users ? (
                    <window.lucide.Users size={20} className="text-gray-500 mt-1 mr-3" />
                  ) : (
                    <span className="mr-3">👥</span>
                  )}
                  <div>
                    <h4 className="font-medium text-gray-800 mb-1">チームメンバー</h4>
                    <p className="text-gray-700">{team.members?.join(", ") || "メンバー情報なし"}</p>
                  </div>
                </div>

                {/* Score Details */}
                <div className="mb-5">
                  <h4 className="font-medium text-gray-800 mb-3">スコア詳細</h4>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-4">
                    {Object.entries(team.scores || {}).map(([key, value]) => (
                      <div key={key} className="flex flex-col space-y-1">
                        <div className="flex justify-between text-sm text-gray-600">
                          <span>
                            {{
                              pronunciation: '発音と明瞭さ',
                              grammar: '文法の正確さ',
                              structure: '構成力',
                              slideQuality: 'スライドの質',
                              expression: '表現力',
                              requiredFeatures: '必須機能',
                              scalability: '拡張性',
                              usability: '使いやすさ',
                              completeness: '完成度',
                              technicalNovelty: '技術革新性',
                              feasibility: '実現可能性',
                              businessAppeal: 'ビジネス魅力',
                              overallImpression: '総合印象'
                            }[key] || key}
                          </span>
                          <span className="font-medium">{value.toFixed(1)}</span>
                        </div>
                        <div className="w-full h-2 bg-gray-200 rounded-full">
                          <div 
                            className={`h-full rounded-full ${barColor}`}
                            style={{
                              width: `${(value / 5) * 100}%`,
                              transition: 'width 0.8s ease-in-out'
                            }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Comment */}
                {team.comment && (
                  <div className="mt-4 border-t pt-4">
                    <h4 className="font-medium text-gray-800 mb-2">チームコメント</h4>
                    <p className="text-gray-700 italic">{team.comment}</p>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
///////////////////////////////////////////////

const renderWinner = () => {
  if (!overallWinner) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg text-center">
          <p className="text-xl">結果はまだ集計中です。しばらくお待ちください。</p>
          <button 
            onClick={() => {
              setShowWinner(false);
              setWinnerRevealed(false);
              setShowConfetti(false);
              setCurrentView('overview');
            }}
            className="mt-4 px-6 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
          >
            戻る
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center px-4">
      <div className={`transition-all duration-1000 w-full max-w-3xl transform ${winnerRevealed ? 'scale-100 opacity-100' : 'scale-90 opacity-0'}`}>
        <div className="bg-white rounded-2xl shadow-2xl overflow-hidden relative">
          
          {/* Decorative Gradient Ribbon */}
          <div className="absolute -top-20 left-1/2 transform -translate-x-1/2 w-[160%] h-60 bg-gradient-to-br from-yellow-400 via-pink-400 to-red-400 rounded-full blur-3xl opacity-30"></div>

          {/* Winner Header */}
          <div className="bg-gradient-to-r from-yellow-400 via-red-400 to-pink-500 py-10 px-6 text-center">
            <div className="w-24 h-24 bg-white rounded-full shadow-md mx-auto flex items-center justify-center animate-bounce mb-4">
              {window.lucide && window.lucide.Trophy ? (
                <window.lucide.Trophy size={48} className="text-yellow-500" />
              ) : (
                <span className="text-5xl">🏆</span>
              )}
            </div>
            <h2 className="text-4xl font-extrabold text-white tracking-wider drop-shadow-lg">総合優勝</h2>
            <p className="text-3xl text-white font-semibold mt-2 tracking-wide">{overallWinner.name}</p>
          </div>

          {/* Score Cards */}
          <div className="flex justify-center gap-6 py-6 px-4 flex-wrap bg-gray-50">
            {[
              { label: 'プレゼン', color: 'text-indigo-600', score: overallWinner.presentationScore },
              { label: '実装', color: 'text-purple-600', score: overallWinner.implementationScore },
              { label: '総合点', color: 'text-amber-600', score: overallWinner.totalScore, highlight: true },
            ].map(({ label, color, score, highlight }, idx) => (
              <div
                key={idx}
                className={`min-w-[100px] px-4 py-3 rounded-xl shadow-lg text-center ${highlight ? 'bg-yellow-100' : 'bg-white'}`}
              >
                <p className={`text-sm font-semibold ${color}`}>{label}</p>
                <p className="text-2xl font-bold text-gray-900">{score.toFixed(2)}</p>
              </div>
            ))}
          </div>

          {/* Team Members */}
          <div className="text-center px-6 pb-6">
            <div className="bg-gray-100 p-4 rounded-xl max-w-md mx-auto shadow-inner mb-4">
              <h4 className="text-gray-700 font-semibold mb-1">チームメンバー</h4>
              <p className="text-gray-900">{overallWinner.members.join(' ・ ')}</p>
            </div>

            {overallWinner.comment && (
              <p className="text-gray-500 italic text-sm max-w-md mx-auto">"{overallWinner.comment}"</p>
            )}
          </div>

          {/* Close Button */}
          <div className="text-center pb-6">
            <button 
              onClick={() => {
                setShowWinner(false);
                setWinnerRevealed(false);
                setShowConfetti(false);
                setCurrentView('overview'); // ✅ This is what makes "結果に戻る" work
              }}
              className="px-6 py-2 bg-gray-700 hover:bg-gray-800 text-white rounded-lg shadow-md transition-all"
            >
              結果に戻る
            </button>
          </div>
        </div>
      </div>

      {/* Confetti */}
      <div className="fixed inset-0 pointer-events-none z-40">
        {Array.from({ length: 80 }).map((_, i) => {
          const size = Math.random() * 8 + 4;
          const colors = [
            'bg-amber-500', 'bg-indigo-500', 'bg-purple-500', 
            'bg-pink-500', 'bg-blue-500', 'bg-red-500', 
            'bg-green-500', 'bg-yellow-500'
          ];
          const color = colors[Math.floor(Math.random() * colors.length)];
          const left = Math.random() * 100;
          const delay = Math.random() * 2;

          return (
            <div 
              key={i}
              className={`absolute ${color} rounded-md animate-fall`}
              style={{
                left: `${left}%`,
                top: '-20px',
                width: `${size}px`,
                height: `${size}px`,
                animationDelay: `${delay}s`,
                animationDuration: `${Math.random() * 3 + 2}s`
              }}
            ></div>
          );
        })}
      </div>
    </div>
  );
};


  return (
    <div className="max-w-3xl mx-auto p-4 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl shadow-xl font-sans">
      <style jsx>{`
        @keyframes fall {
          0% { transform: translateY(0) rotate(0); opacity: 1; }
          100% { transform: translateY(600px) rotate(720deg); opacity: 0; }
        }
        
        .animate-fall {
          animation: fall 2s ease-in forwards;
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 0.4; }
          50% { opacity: 0.8; }
        }
        
        .animate-pulse {
          animation: pulse 2s ease-in-out infinite;
        }
        
        @keyframes bounce {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-15px); }
        }
        
        .animate-bounce {
          animation: bounce 2s ease-in-out infinite;
        }
      `}</style>
      
      <header className="text-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-1">IIT 研修：ハッカソン最終報告会</h1>
        <p className="text-gray-600">2025/5/16</p>
      </header>
      
      <div className="bg-white p-4 rounded-xl shadow-lg relative overflow-hidden">
        {/* Decorative background element */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-50 to-purple-50 rounded-full -mr-24 -mt-24 opacity-70"></div>
        <div className="absolute bottom-0 left-0 w-48 h-48 bg-gradient-to-tr from-amber-50 to-yellow-50 rounded-full -ml-24 -mb-24 opacity-70"></div>
        
        <div className="relative z-10">
          {currentView === 'overview' && renderOverview()}
          
          {currentView === 'presentation' && renderDetailedResults(
            'presentation',
            rankedPresentationTeams,
            'プレゼン力賞',
            'プレゼンテーションスキル、発表内容、表現力を評価',
            'from-indigo-600 via-blue-600 to-indigo-700'
          )}
          
          {currentView === 'implementation' && renderDetailedResults(
            'implementation',
            rankedImplementationTeams,
            '実装力賞',
            '技術的完成度、使いやすさ、実用性、運用への貢献度を評価',
            'from-purple-600 via-fuchsia-600 to-purple-700'
          )}
        </div>
      </div>
      
      {showWinner && renderWinner()}
    </div>
  );
};
 