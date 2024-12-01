#pragma once

#define FRAME_BUFFER_WIDTH		800
#define FRAME_BUFFER_HEIGHT		600

#include "Timer.h"
#include "Player.h"
#include "Scene.h"

class MainCScene;

class CGameFramework
{
public:
	CGameFramework();
	~CGameFramework();
	//direct3D 초기 설정 및 해제
	bool OnCreate(HINSTANCE hInstance, HWND hMainWnd);
	void OnDestroy();
	//스왑 체인 및 디바이스 장치 명령큐와 리스트 생성
	void CreateSwapChain();
	void CreateDirect3DDevice();
	void CreateCommandQueueAndList();
	//렌더 타겟 뷰와 깊이 스텐실 뷰 힙생성
	void CreateRtvAndDsvDescriptorHeaps();
	//렌더 타겟 뷰와 깊이 스텐실 뷰 생성
	void CreateRenderTargetViews();
	void CreateDepthStencilView();
	//스왑체인 상태 변환
	void ChangeSwapChainState();
	//객체 생성 및 설정
    void BuildObjects();
    void ReleaseObjects();
	//키보드 이벤트 및 
    void ProcessInput();
    void AnimateObjects();
    void FrameAdvance();
	//동기화 및 프레임 자원 설정
	void WaitForGpuComplete();
	void MoveToNextFrame();
	//마우스 및 키보드 이벤트 설정
	void OnProcessingMouseMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	void OnProcessingKeyboardMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	LRESULT CALLBACK OnProcessingWindowMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	
	//지금 씬이 뭔지 체크
	//게임 시작화면-> 1
	//인게임 화면 -> 2
	//메뉴 화면 -> 3
	int							check = 0;
private:
	HINSTANCE					m_hInstance;
	HWND						m_hWnd; 

	int							m_nWndClientWidth;
	int							m_nWndClientHeight;
        
	IDXGIFactory4				*m_pdxgiFactory = NULL;
	IDXGISwapChain3				*m_pdxgiSwapChain = NULL;
	ID3D12Device				*m_pd3dDevice = NULL;

	bool						m_bMsaa4xEnable = false;
	UINT						m_nMsaa4xQualityLevels = 0;

	static const UINT			m_nSwapChainBuffers = 2;
	UINT						m_nSwapChainBufferIndex;

	ID3D12Resource				*m_ppd3dSwapChainBackBuffers[m_nSwapChainBuffers];
	ID3D12DescriptorHeap		*m_pd3dRtvDescriptorHeap = NULL;

	ID3D12Resource				*m_pd3dDepthStencilBuffer = NULL;
	ID3D12DescriptorHeap		*m_pd3dDsvDescriptorHeap = NULL;

	ID3D12CommandAllocator		*m_pd3dCommandAllocator = NULL;
	ID3D12CommandQueue			*m_pd3dCommandQueue = NULL;
	ID3D12GraphicsCommandList	*m_pd3dCommandList = NULL;

	ID3D12Fence					*m_pd3dFence = NULL;
	UINT64						m_nFenceValues[m_nSwapChainBuffers];
	HANDLE						m_hFenceEvent;

#if defined(_DEBUG)
	ID3D12Debug					*m_pd3dDebugController;
#endif

	CGameTimer					m_GameTimer;

	int							m_nScenes = 0;
	CScene						**m_ppScenes = NULL;

	int							m_nScene = 0;
	CScene						*m_pScene = NULL;

	CPlayer						*m_pPlayer = NULL;

	CCamera						*m_pCamera = NULL;

	POINT						m_ptOldCursorPos;

	_TCHAR						m_pszFrameRate[70];
};

