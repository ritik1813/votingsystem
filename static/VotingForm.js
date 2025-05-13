const teams = [1, 2, 3];

const evaluationDescriptions = {
  presentationSkills: {
    pronunciation: {
      label: '発音・聞き取りやすさ',
      description: '発音・イントネーションが明瞭で、聞き取りやすい話し方になっているか'
    },
    grammar: {
      label: '文法の正確さ',
      description: '不自然な表現や誤用が少なく、日本語文法に沿って適切に話せているか'
    },
    structure: {
      label: '話の流れ・構成力',
      description: '話の展開が論理的で整理されており、伝えたいポイントが明確になっているか'
    },
    slideQuality: {
      label: 'プレゼン資料の完成度',
      description: 'スライドが見やすく整っており、図表・テキスト・デザインに工夫があるか'
    },
    expression: {
      label: '表現の工夫・印象',
      description: '聞き手に伝わる表現・抑揚・感情の込め方など、印象に残るプレゼンになっているか'
    }
  },
  implementationQuality: {
    requiredFeatures: {
      label: '必須機能の実装度',
      description: '認証、位置情報、帳票出力などの必須機能が確実に動作するか'
    },
    scalability: {
      label: '拡張性',
      description: '今後の機能追加（例：休暇管理、給与連携）への対応がしやすい構造か'
    },
    usability: {
      label: '操作性・使用感',
      description: '誰でも直感的に操作できるデザインか（UI/UX）'
    },
    completeness: {
      label: '完成度',
      description: '全体的にエラーが少なく、安定して使える仕上がりになっているか'
    },
    technicalNovelty: {
      label: '技術の新規性・独自性',
      description: '既存の勤怠アプリにはない仕組み・発想が取り入れられているか'
    },
    feasibility: {
      label: '実現可能性',
      description: '現実の業務にそのまま導入できるか、現実性があるか'
    },
    businessAppeal: {
      label: '営業的な魅力',
      description: '顧客にとっての導入価値が明確で、「欲しい」と思わせる内容か'
    },
    overallImpression: {
      label: '総合的印象（人気投票）',
      description: '実際に試した来場者が「一番良い」と感じたかどうか（ライト評価）'
    }
  }
};

const VotingForm = () => {
  const [currentTeam, setCurrentTeam] = React.useState(1);
  const [submittedTeams, setSubmittedTeams] = React.useState({});
  const [submitting, setSubmitting] = React.useState(false);
  const [errorMessage, setErrorMessage] = React.useState('');
  const [hoveredRating, setHoveredRating] = React.useState({ team: null, cat: null, subcat: null, rating: 0 });
  const [formData, setFormData] = React.useState(() => {
    const init = {};
    teams.forEach((t) => {
      init[`team${t}`] = {
        presentationSkills: Object.fromEntries(Object.keys(evaluationDescriptions.presentationSkills).map(k => [k, 0])),
        implementationQuality: Object.fromEntries(Object.keys(evaluationDescriptions.implementationQuality).map(k => [k, 0])),
        comments: '' // One comment field per team
      };
    });
    return init;
  });

  // Debug log to verify form data structure
  console.log("Current form data:", formData);
  console.log("Submitted teams:", submittedTeams);

  const handleRating = (team, cat, subcat, rating) => {
    console.log(`Setting rating for team${team}, ${cat}, ${subcat} to ${rating}`);
    setFormData(prev => ({
      ...prev,
      [`team${team}`]: {
        ...prev[`team${team}`],
        [cat]: {
          ...prev[`team${team}`][cat],
          [subcat]: rating
        }
      }
    }));
  };

  const handleComment = (team, comment) => {
    console.log(`Setting comment for team${team}`);
    setFormData(prev => ({
      ...prev,
      [`team${team}`]: {
        ...prev[`team${team}`],
        comments: comment
      }
    }));
  };

  const handleStarHover = (team, cat, subcat, rating) => {
    setHoveredRating({ team, cat, subcat, rating });
  };

  const handleStarLeave = () => {
    setHoveredRating({ team: null, cat: null, subcat: null, rating: 0 });
  };

  const isTeamComplete = (team) => {
    const data = formData[`team${team}`];
    const presentationComplete = Object.values(data.presentationSkills).every(val => val > 0);
    const implementationComplete = Object.values(data.implementationQuality).every(val => val > 0);
    
    console.log(`Team ${team} completion status:`, { 
      presentationComplete, 
      implementationComplete,
      presentationScores: data.presentationSkills,
      implementationScores: data.implementationQuality
    });
    
    return presentationComplete && implementationComplete;
  };

  const isTeamSubmitted = (team) => {
    return submittedTeams[`team${team}`] === true;
  };

  // Enhanced star rendering with animations and effects
  const renderStars = (team, cat, subcat) => {
    const currentRating = formData[`team${team}`][cat][subcat];
    const isHovering = hoveredRating.team === team && hoveredRating.cat === cat && hoveredRating.subcat === subcat;
    const hoverRating = isHovering ? hoveredRating.rating : 0;
    const isDisabled = isTeamSubmitted(team);
    
    return (
      <div className="flex gap-1 sm:gap-2 mt-2">
        {[1, 2, 3, 4, 5].map(i => {
          // Determine if star should be filled based on current selection or hover state
          const isFilled = isHovering ? i <= hoverRating : i <= currentRating;
          // Add pulsing effect to the star that would be selected on click during hover
          const isPulsing = isHovering && i === hoverRating && !isDisabled;
          
          return (
            <button
              key={i}
              type="button"
              disabled={isDisabled}
              className={`relative p-1 transition duration-200 ${isPulsing ? 'animate-pulse' : ''} ${isDisabled ? 'cursor-default' : ''}`}
              onClick={() => !isDisabled && handleRating(team, cat, subcat, i)}
              onMouseEnter={() => !isDisabled && handleStarHover(team, cat, subcat, i)}
              onMouseLeave={() => !isDisabled && handleStarLeave()}
              onTouchStart={() => !isDisabled && handleStarHover(team, cat, subcat, i)}
              onTouchEnd={() => !isDisabled && handleStarLeave()}
            >
              <span 
                className={`text-xl sm:text-2xl transition-all duration-300 ease-in-out transform ${
                  isFilled 
                    ? isDisabled ? 'text-yellow-300' : 'text-yellow-400 drop-shadow-lg' 
                    : 'text-gray-300'
                } ${
                  isPulsing 
                    ? 'scale-125' 
                    : isHovering && i <= hoverRating && !isDisabled
                      ? 'scale-110' 
                      : ''
                } ${isDisabled ? 'opacity-80' : ''}`}
              >
                ★
              </span>
              {isPulsing && (
                <span className="absolute inset-0 bg-yellow-200 opacity-30 rounded-full animate-ping"></span>
              )}
            </button>
          );
        })}
      </div>
    );
  };

  // Comment text box at the end for each team
  const renderTeamCommentBox = (team) => {
    const isDisabled = isTeamSubmitted(team);
    const comment = formData[`team${team}`].comments;
    
    return (
      <div className="mt-6 mb-4 p-3 sm:p-4 bg-gray-50 rounded-lg border border-gray-200">
        <h3 className="text-base sm:text-lg font-medium text-gray-700 mb-2">コメント（任意）</h3>
        <p className="text-xs sm:text-sm text-gray-500 mb-2">このチームについて追加のフィードバックがあれば、ご記入ください。</p>
        <textarea
          placeholder="例: プレゼンはとても分かりやすかったです。実装に関しては..."
          value={comment}
          onChange={(e) => handleComment(team, e.target.value)}
          disabled={isDisabled}
          className={`w-full p-2 sm:p-3 text-sm border rounded-md ${
            isDisabled 
              ? 'bg-gray-100 text-gray-500 border-gray-200' 
              : 'border-gray-300 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50'
          }`}
          rows="4"
        />
      </div>
    );
  };
  
  const handleSubmitTeam = (team) => {
    // Check if the current team is fully evaluated
    if (isTeamComplete(team)) {
      // Set submitting state to show loading
      setSubmitting(true);
      setErrorMessage('');
      
      const teamData = { [`team${team}`]: formData[`team${team}`] };
      console.log(`Submitting data for team ${team}:`, teamData);
      
      // Send the data to the server
      fetch('/api/submit-votes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(teamData),
      })
      .then(response => {
        if (!response.ok) {
          throw new Error(`Server returned ${response.status}: ${response.statusText}`);
        }
        return response.json();
      })
      .then(data => {
        console.log('Success:', data);
        // Mark this team as submitted
        setSubmittedTeams(prev => ({
          ...prev,
          [`team${team}`]: true
        }));
        setSubmitting(false);
        
        // Move to next team if available
        if (team < Math.max(...teams) && !isTeamSubmitted(team + 1)) {
          setCurrentTeam(team + 1);
        }
      })
      .catch((error) => {
        console.error('Error:', error);
        setErrorMessage(`送信エラー: ${error.message}`);
        setSubmitting(false);
      });
    } else {
      setErrorMessage(`チーム${team}のすべての項目を入力してください`);
    }
  };
  
  const handleReset = (team) => {
    if (window.confirm(`チーム${team}の評価をリセットしますか？`)) {
      setFormData(prev => ({
        ...prev,
        [`team${team}`]: {
          presentationSkills: Object.fromEntries(Object.keys(evaluationDescriptions.presentationSkills).map(k => [k, 0])),
          implementationQuality: Object.fromEntries(Object.keys(evaluationDescriptions.implementationQuality).map(k => [k, 0])),
          comments: ''
        }
      }));
      
      // If this team was submitted, mark it as not submitted
      if (submittedTeams[`team${team}`]) {
        setSubmittedTeams(prev => {
          const updated = { ...prev };
          delete updated[`team${team}`];
          return updated;
        });
      }
    }
  };

  // Check if all teams have been submitted
  const allTeamsSubmitted = teams.every(t => isTeamSubmitted(t));
  
  if (allTeamsSubmitted) {
    return (
      <div className="text-center py-8 sm:py-10 animate-fade-in px-4">
        <div className="text-green-600 text-3xl sm:text-4xl mb-4">
          {window.lucide && window.lucide.Check ? (
            <window.lucide.Check size={48} />
          ) : (
            <span style={{ fontSize: '48px' }}>✓</span>
          )}
        </div>
        <h2 className="text-xl sm:text-2xl font-bold">ありがとうございました！</h2>
        <p className="text-gray-600">すべてのチームの評価が正常に送信されました。</p>
        <button
          onClick={() => setSubmittedTeams({})}
          className="mt-6 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg shadow-md"
        >
          新しい評価を始める
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-3 sm:px-6 py-6 sm:py-10 bg-gradient-to-br from-sky-100 to-indigo-100 rounded-lg sm:rounded-xl shadow-xl sm:shadow-2xl">
      <h1 className="text-2xl sm:text-3xl font-bold text-center mb-6 sm:mb-8 text-indigo-800">🎓 ハッカソン 投票フォーム</h1>

      <div className="flex justify-center flex-wrap sm:flex-nowrap gap-2 sm:gap-6 mb-4 sm:mb-6">
        {teams.map((team) => (
          <button
            key={team}
            type="button"
            onClick={() => setCurrentTeam(team)}
            className={`px-3 sm:px-5 py-1 sm:py-2 rounded-full text-base sm:text-lg font-semibold transition shadow-md transform hover:scale-105 ${
              currentTeam === team 
                ? 'bg-indigo-600 text-white' 
                : isTeamSubmitted(team) 
                  ? 'bg-green-500 text-white' 
                  : isTeamComplete(team) 
                    ? 'bg-green-200 text-green-900' 
                    : 'bg-gray-200 text-gray-700'
            }`}
          >
            チーム {team} {isTeamSubmitted(team) && '✓'}
          </button>
        ))}
      </div>

      <div key={currentTeam} className="bg-white p-4 sm:p-6 rounded-lg shadow-md">
        {isTeamSubmitted(currentTeam) ? (
          <div className="text-center py-6 sm:py-8">
            <div className="text-green-500 text-xl sm:text-2xl mb-3 sm:mb-4">✓</div>
            <h3 className="text-lg sm:text-xl font-semibold">チーム{currentTeam}の評価は送信済みです</h3>
            <button
              onClick={() => handleReset(currentTeam)}
              className="mt-4 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg shadow-md"
            >
              リセット
            </button>
          </div>
        ) : (
          <>
            {Object.entries(evaluationDescriptions).map(([catKey, subcats]) => (
              <div key={catKey} className="mb-6 sm:mb-8">
                <h2 className="text-lg sm:text-xl font-bold text-indigo-700 mb-3 sm:mb-4">
                  {catKey === 'presentationSkills' ? '🎤 プレゼン力賞' : '💻 実装力賞'}
                </h2>
                {Object.entries(subcats).map(([key, { label, description }]) => (
                  <div key={key} className="mb-4 pb-3 border-b border-gray-100">
                    <div className="text-sm font-medium text-gray-700">{label}</div>
                    <div className="text-xs text-gray-500 italic">{description}</div>
                    {renderStars(currentTeam, catKey, key)}
                  </div>
                ))}
              </div>
            ))}
            
            {/* Single comment box for the team */}
            {renderTeamCommentBox(currentTeam)}

            <div className="flex flex-col sm:flex-row justify-between items-center gap-4 mt-6 sm:mt-8">
              <div className="w-full sm:w-auto flex justify-between sm:justify-start gap-2">
                {currentTeam > 1 && (
                  <button
                    type="button"
                    onClick={() => setCurrentTeam(currentTeam - 1)}
                    className="px-3 sm:px-4 py-2 rounded-lg bg-gray-300 hover:bg-gray-400 text-gray-800 shadow-md text-sm sm:text-base"
                  >
                    ← 前へ
                  </button>
                )}
                
                {currentTeam < Math.max(...teams) && (
                  <button
                    type="button"
                    onClick={() => setCurrentTeam(currentTeam + 1)}
                    className="px-3 sm:px-4 py-2 rounded-lg bg-gray-300 hover:bg-gray-400 text-gray-800 shadow-md text-sm sm:text-base"
                  >
                    次へ →
                  </button>
                )}
              </div>
              
              <div className="w-full sm:w-auto flex gap-2 sm:gap-4">
                <button
                  type="button"
                  onClick={() => handleReset(currentTeam)}
                  className="flex-1 sm:flex-none px-3 sm:px-4 py-2 rounded-lg bg-red-500 hover:bg-red-600 text-white shadow-md text-sm sm:text-base"
                >
                  リセット
                </button>
                
                <button
                  type="button"
                  onClick={() => handleSubmitTeam(currentTeam)}
                  disabled={!isTeamComplete(currentTeam) || submitting}
                  className={`flex-1 sm:flex-none px-3 sm:px-6 py-2 rounded-lg shadow-md text-white text-sm sm:text-base ${
                    isTeamComplete(currentTeam) 
                      ? submitting 
                        ? 'bg-green-400 cursor-wait' 
                        : 'bg-green-600 hover:bg-green-700' 
                      : 'bg-green-300 cursor-not-allowed'
                  }`}
                >
                  {submitting ? '送信中...' : 'チーム評価を送信'} 
                  {!submitting && window.lucide && window.lucide.Send ? (
                    <window.lucide.Send className="inline ml-2" size={16} />
                  ) : null}
                </button>
              </div>
            </div>

            {errorMessage && (
              <div className="mt-4 sm:mt-6 p-3 sm:p-4 border border-red-300 bg-red-50 rounded-md text-red-800 flex items-center gap-2 text-sm">
                {window.lucide && window.lucide.AlertCircle ? (
                  <window.lucide.AlertCircle size={20} />
                ) : (
                  <span>⚠️</span>
                )} 
                {errorMessage}
              </div>
            )}

            {!isTeamComplete(currentTeam) && (
              <div className="mt-4 sm:mt-6 p-3 sm:p-4 border border-yellow-300 bg-yellow-50 rounded-md text-yellow-800 flex items-center gap-2 text-sm">
                {window.lucide && window.lucide.AlertCircle ? (
                  <window.lucide.AlertCircle size={20} />
                ) : (
                  <span>⚠️</span>
                )} 
                すべての項目を入力してください。
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};