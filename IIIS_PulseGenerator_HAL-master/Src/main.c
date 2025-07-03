/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2019 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <math.h>
#include "ssd1306.h"
#include "fonts.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

I2C_HandleTypeDef hi2c1;

TIM_HandleTypeDef htim2;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
uint16_t adcValue[2];
long tim2_count=0;
float NormalizeParameter[2];
float threshold = 70;
float duration = 10;
float phase = 0;
float phase_ms = 0;
float inactive_time = 0;
float mode = 2;
char buf[32] = {};
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_ADC1_Init(void);
static void MX_I2C1_Init(void);
static void MX_TIM2_Init(void);
static void MX_USART2_UART_Init(void);
/* USER CODE BEGIN PFP */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim);
void SetUpNormalizeParameter(float NormalizeParameter[2]);
void DrawParameter(int count);
void UserSetUp(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_ADC1_Init();
  MX_I2C1_Init();
  MX_TIM2_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  ssd1306_Init();

  HAL_ADC_Start_DMA(&hadc1,(uint32_t *)adcValue,2); //ADC-DMAを有効化

  HAL_Delay(1000);

  STARTUP_LABEL:

//  sprintf(buf, "START UP\r\n");
//  HAL_UART_Transmit(&huart2, (uint8_t*)buf, sizeof(buf), 10);

  UserSetUp(); //計測開始前設定処理
  SetUpNormalizeParameter(NormalizeParameter); //AD値の平均値と標準偏差を計算

  RESTART_LABEL:

//  sprintf(buf, "RESTART\r\n");
//  HAL_UART_Transmit(&huart2, (uint8_t*)buf, sizeof(buf), 10);

  /*------------Draw LCD BEGIN----------*/
  sprintf(buf, "ave=%d sd=%d", (int)(NormalizeParameter[0]),(int)(NormalizeParameter[1]));
  HAL_UART_Transmit(&huart2, (uint8_t*)buf, sizeof(buf), 0xFFF);

  ssd1306_Fill(White);

  ssd1306_SetCursor(0,0);
  ssd1306_WriteString(buf,Font_7x10,Black);

  sprintf(buf, "Waiting for start");
  ssd1306_SetCursor(0,12);
  ssd1306_WriteString(buf,Font_7x10,Black);

  ssd1306_UpdateScreen();
  /*------------Draw LCD END---------*/

  while(1){ // REMシグナル待ち (計測待機状態)
	  if(HAL_GPIO_ReadPin(GPIOC, REM_SIG_Pin) == 1){
		ssd1306_Fill(White);
		sprintf(buf, "RUNNING");
		ssd1306_SetCursor(0,0);
		ssd1306_WriteString(buf,Font_7x10,Black);
		ssd1306_UpdateScreen();
		HAL_Delay(300);
		break;
	  }
  }

  HAL_TIM_Base_Start_IT(&htim2); //タイマー割り込み機能を有効化 (つまり、割り込み関数である"ピークを発見したらパルスを生む関数"を有効化)
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while(1) { //REMシグナルが来ているときに実行する処理

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
	  if(HAL_GPIO_ReadPin(GPIOC, REM_SIG_Pin) == 0){ //シグナルが終了したら
		HAL_TIM_Base_Stop_IT(&htim2); //タイマー割り込み機能をオフ(もうパルス出す必要ないもんね)
		HAL_Delay(300);
		HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,RESET);
		goto RESTART_LABEL;
	  }
	  if(HAL_GPIO_ReadPin(GPIOB, RIGHT_B_Pin) == 0){ //右ボタンを押したら強制終了 & 設定に戻る  // <----------------------- ここにフットスイッチのif文の代わりに条件文を入れる
		  HAL_TIM_Base_Stop_IT(&htim2); //タイマー割り込み機能をオフ(もうパルス出す必要ないもんね)
		  HAL_Delay(300);
		  HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,RESET);
		  goto STARTUP_LABEL;
	 }
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE3);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 2;
  RCC_OscInitStruct.PLL.PLLR = 2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC1_Init(void)
{

  /* USER CODE BEGIN ADC1_Init 0 */

  /* USER CODE END ADC1_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC1_Init 1 */

  /* USER CODE END ADC1_Init 1 */

  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
  hadc1.Init.Resolution = ADC_RESOLUTION_12B;
  hadc1.Init.ScanConvMode = ENABLE;
  hadc1.Init.ContinuousConvMode = ENABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 1;
  hadc1.Init.DMAContinuousRequests = DISABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = 1;
  sConfig.SamplingTime = ADC_SAMPLETIME_480CYCLES;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC1_Init 2 */
  hadc1.Init.DMAContinuousRequests = ENABLE;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE END ADC1_Init 2 */

}

/**
  * @brief I2C1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C1_Init(void)
{

  /* USER CODE BEGIN I2C1_Init 0 */

  /* USER CODE END I2C1_Init 0 */

  /* USER CODE BEGIN I2C1_Init 1 */

  /* USER CODE END I2C1_Init 1 */
  hi2c1.Instance = I2C1;
  hi2c1.Init.ClockSpeed = 100000;
  hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c1.Init.OwnAddress1 = 0;
  hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c1.Init.OwnAddress2 = 0;
  hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
  if (HAL_I2C_Init(&hi2c1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C1_Init 2 */

  /* USER CODE END I2C1_Init 2 */

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 83;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 999;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA2_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA2_Stream0_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA2_Stream0_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA2_Stream0_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : UP_B_Pin FOOT_SW_Pin RIGHT_B_Pin LEFT_B_Pin */
  GPIO_InitStruct.Pin = UP_B_Pin|FOOT_SW_Pin|RIGHT_B_Pin|LEFT_B_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pin : REM_SIG_Pin */
  GPIO_InitStruct.Pin = REM_SIG_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  HAL_GPIO_Init(REM_SIG_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : DOWN_B_Pin */
  GPIO_InitStruct.Pin = DOWN_B_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(DOWN_B_GPIO_Port, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim){ //タイマー割り込みによって呼び出されるコールバック関数
	static long phase_tim = 0;
	static int phase_flag = 0;
	static float d1;
	static float d2;
	static float d3;

	if(htim->Instance == TIM2){ //割り込みするタイマーがtim2だった場合の処理
		d1 = d2;
		d2 = d3;
		d3 = (adcValue[0] - NormalizeParameter[0])/ NormalizeParameter[1]; //Z得点(平均50,標準偏差10の値域に変換したものつまり偏差値)

		if(d2 > threshold/100.0f && d1 < d2 && d2 > d3 && tim2_count > 100 && tim2_count > inactive_time && ((int)mode % 2) == 0){ //peak detect
			//HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,SET);
			tim2_count = 0;
			phase_flag = 1;
			phase_tim = 0;

		}else if(d2 < threshold/100.0f && d1 > d2 && d2 < d3 && tim2_count > 100 && tim2_count > inactive_time && ((int)mode % 2) == 1){ //trough detect
			//HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,SET);
			tim2_count = 0;
			phase_flag = 1;
			phase_tim = 0;

		}

		if(HAL_GPIO_ReadPin(LD2_GPIO_Port, LD2_Pin) == 0 && phase_flag == 1 && phase_tim > phase_ms){ //phase passed
			HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,SET);
		}else if(phase_flag == 1 && phase_tim > phase_ms + duration){ //phase+duration passed
			HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,RESET);
			phase_flag = 0;
			phase_tim = 0;
		}

		/*こっから玉井の試験用プログラム*/

//		if(phase_tim > phase_ms){ //phase passed
//			HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,SET);
//
//			sprintf(buf, "phase_tim > phase_ms : %lo > %lo \r\n", phase_tim, phase_ms);
//			HAL_UART_Transmit(&huart2, (uint8_t*)buf, sizeof(buf), 10);
//		}
//
//		if(phase_tim > phase_ms + duration){ //phase+duration passed
//			HAL_GPIO_WritePin(LD2_GPIO_Port,LD2_Pin,RESET);
//			phase_flag = 0;
//			phase_tim = 0;
//			HAL_Delay(500);
//
//			sprintf(buf, "phase_tim > phase_ms + duration : %lo > %lo \r\n", phase_tim, phase_ms+duration);
//			HAL_UART_Transmit(&huart2, (uint8_t*)buf, sizeof(buf), 10);
//		}

		/*ここまで玉井の試験用プログラム*/

	}
	tim2_count++;
	phase_tim++; //UserSetUpで事前に設定した位相遅らせ時間phaseとパルス幅durationの合計を超えるまでカウンターを回し続ける。
}

void SetUpNormalizeParameter(float NormalizeParameter[2]){
	float data[4096] = {0};
	long sum = 0;
	for(int i = 0; i < 4096; i++){
		data[i] = adcValue[0];
		sum += data[i];
		HAL_Delay(1);/*こっから玉井の試験用プログラム*/
	}
	NormalizeParameter[0] = sum/4096.0f; //adcのデータの平均値
	sum = 0;
	for(int i = 0; i < 4096; i++){
		sum += pow(data[i] - NormalizeParameter[0],2);
	}
	NormalizeParameter[1] = pow(sum/4096.0f,0.5); //adcのデータの標準偏差
}

void DrawParameter(int count){
	char buf[32] = {};

	ssd1306_Fill(White);

	ssd1306_SetCursor(0,0);
	sprintf(buf,"%sth=%d [%%]",count==0?"*":" ", (int)threshold);
	ssd1306_WriteString(buf,Font_7x10,Black);

	ssd1306_SetCursor(0,12);
	sprintf(buf,"%sdu=%d [ms]",count==1?"*":" ", (int)duration);
	ssd1306_WriteString(buf,Font_7x10,Black);

	ssd1306_SetCursor(0,24);
	sprintf(buf,"%sph=%d [deg]",count==2?"*":" ", (int)phase);
	ssd1306_WriteString(buf,Font_7x10,Black);

	ssd1306_SetCursor(0,36);
	sprintf(buf,"%sinactive=%d [ms]",count==3?"*":" ", (int)inactive_time);
	ssd1306_WriteString(buf,Font_7x10,Black);

	ssd1306_SetCursor(0,48);
	sprintf(buf,"%smode=%s ",count==4?"*":" ",  ((int)mode % 2) == 1 ? "trough":"peak");
	ssd1306_WriteString(buf,Font_7x10,Black);

	ssd1306_UpdateScreen();
}

void UserSetUp(void){ //計測開始前設定処理

	  char buf[32] = {};
	  int count = 0;
	  float *param_pointer;
	  param_pointer = &threshold;

	  ssd1306_Fill(White);
	  ssd1306_UpdateScreen();
	  DrawParameter(0);

	  while(1){ //プッシュボタンによるモード・閾値設定
		if(HAL_GPIO_ReadPin(GPIOB, UP_B_Pin) == 0){ //UP button
			switch(count){
				case 0:
					*param_pointer += 1.0f; //change value of destination of pointer
					break;
				case 2:
					*param_pointer += 10.0f;
					break;
				case 3:
					*param_pointer += 100.0f;
					break;
				default:
					*param_pointer += 1.0f;
					break;
			}
			DrawParameter(count);

		}else if(HAL_GPIO_ReadPin(DOWN_B_GPIO_Port, DOWN_B_Pin) == 0){ //down button
			switch(count){
				case 0:
					*param_pointer -= 1.0f;
					break;
				case 2:
					*param_pointer -= 10.0f;
					break;
				case 3:
					*param_pointer -= 100.0f;
					break;
				default:
					*param_pointer -= 1.0f;
					break;
			}
			DrawParameter(count);

		}else if(HAL_GPIO_ReadPin(GPIOB, LEFT_B_Pin) == 0){ //left button pressed
			count++;
			switch(count){
				case 0:
					param_pointer = &threshold; //change pointer destination
					DrawParameter(count);
					break;
				case 1:
					param_pointer = &duration;
					DrawParameter(count);
					break;
				case 2:
					param_pointer = &phase;
					DrawParameter(count);
					break;
				case 3:
					param_pointer = &inactive_time;
					DrawParameter(count);
					break;
				case 4:
					param_pointer = &mode;
					DrawParameter(count);
					break;
				default:
					param_pointer = &threshold;
					count = 0;
					DrawParameter(count);
					break;
			}
			HAL_Delay(100);
		}else if(HAL_GPIO_ReadPin(GPIOB, RIGHT_B_Pin) == 0){
			sprintf(buf,"Setting Complete");
			ssd1306_Fill(White);
			ssd1306_SetCursor(0,0);
			ssd1306_WriteString(buf,Font_7x10,Black);

			sprintf(buf,"Waiting for Learning");
			ssd1306_SetCursor(0,12);
			ssd1306_WriteString(buf,Font_7x10,Black);

			ssd1306_UpdateScreen();
			HAL_Delay(500);
			break;
		}
	  }
	  while(1){
		  if(HAL_GPIO_ReadPin(GPIOB, RIGHT_B_Pin) == 0){
			  sprintf(buf,"Learning...");
			  ssd1306_Fill(White);
			  ssd1306_SetCursor(0,0);
			  ssd1306_WriteString(buf,Font_7x10,Black);
			  ssd1306_UpdateScreen();
			  break;
		  }
	  }
	  phase_ms = (phase/360.0f)*142.0f;
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */

  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
