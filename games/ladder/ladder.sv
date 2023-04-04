// ladder game port from Arduino

`default_nettype none
`timescale 1ns / 1ps

module ladder
#(
	parameter CLOCK_FREQ_Mhz = 12,
	parameter START_TIMER_ms = 400,
	parameter DECREASE_TIMER_ms = 32,
	parameter LED_COUNT = 8
)
(
	input i_Clock,
	input i_Button,  // sync, 1 clock event Button Down

	output [LED_COUNT - 1:0] o_LED,  // PMOD-LED display
	output logic [4 * 8 - 1:0] message  // game state message
);

localparam START_COUNTER = CLOCK_FREQ_Mhz * START_TIMER_ms * 1000;
localparam DECREASE_COUNTER = CLOCK_FREQ_Mhz * DECREASE_TIMER_ms * 1000;
localparam LEVELDOWN_COUNTER = START_COUNTER / 3;

localparam COUNTER_WIDTH = $clog2(START_COUNTER);

enum {s_START_GAME1, s_START_GAME2, s_INIT_LEVEL, s_PAUSE_LEVEL, s_WAIT_INPUT, s_LEVEL_UP, s_LEVEL_DOWN, s_VICTORY} sm_state;

logic [COUNTER_WIDTH - 1:0] counter_limit = LEVELDOWN_COUNTER;
logic [COUNTER_WIDTH - 1:0] counter;

logic [$clog2(LED_COUNT) - 1:0] level;
logic [LED_COUNT - 1:0] active_leds;
logic led_on;
logic [1:0] ignore_first;

logic [4:0] glow_pwm;  // glow for victory
logic [3:0] glow_intensity;

assign glow_intensity = counter[COUNTER_WIDTH - 1] ? counter[COUNTER_WIDTH - 1 -: 4] : ~counter[COUNTER_WIDTH - 1 -: 4];

always @(posedge i_Clock) begin

	case (sm_state)

	s_START_GAME1: begin
		message <= "ladd";//"go -";//"push";
		if (i_Button) begin
			level <= 0;
			sm_state <= s_INIT_LEVEL;
		end
		else begin
			if (counter == counter_limit) begin
				active_leds <= &level ? ~0 : (1 << level) - 1;
				counter <= 0;
				level <= level + 1;
			end
			else
				counter <= counter + 1;
		end
	end

	s_INIT_LEVEL: begin
		counter <= 0;
		active_leds <= (1 << level) - 1;
		counter_limit <= START_COUNTER;
		sm_state <= s_PAUSE_LEVEL;
	end

	s_PAUSE_LEVEL: begin
		if (counter == counter_limit) begin
			message <= {"le ", "0" + {5'b0, level}};
			counter <= 0;
			led_on <= 1;
			counter_limit <= START_COUNTER - DECREASE_COUNTER * level;
			ignore_first <= ~0;
			sm_state <= s_WAIT_INPUT;
		end
		else
			counter <= counter + 1;
	end

	s_WAIT_INPUT: begin
		if (counter == counter_limit) begin
			counter <= 0;
			active_leds <= (led_on ? 0 : 1 << level);
			led_on <= ~led_on;
			if (led_on && ignore_first != 0)
				ignore_first <= ignore_first - 1;
		end
		else begin
			if (ignore_first == 0 && i_Button == 1) begin
				if (led_on) begin  // pressed in time
					sm_state <= s_LEVEL_UP;
				end
				else begin  // miss
					counter <= 0;
					led_on <= 1;
					counter_limit <= LEVELDOWN_COUNTER;
					sm_state <= s_LEVEL_DOWN;
				end
			end
			else
				counter <= counter + 1;
		end
	end

	s_LEVEL_UP: begin
		//message <= "good";
		if (&level) begin
			counter_limit <= START_COUNTER / 8;
			sm_state <= s_VICTORY;
		end
		else begin
			level <= level + 1;
			sm_state <= s_INIT_LEVEL;
		end
	end

	s_LEVEL_DOWN, s_START_GAME2: begin
		message <= sm_state == s_LEVEL_DOWN ? "fail" : 0;
		if (counter == counter_limit) begin
			counter <= 0;
			if (~led_on)
				active_leds <= 1 << level;
			else begin
				active_leds <= 0;
				if (level != 0) begin
					level <= level - 1;
				end
				else begin
					sm_state <= s_INIT_LEVEL;
				end
			end
			led_on <= ~led_on;
		end
		else
			counter <= counter + 1;
	end

	s_VICTORY: begin
		message <= "yeah";
		glow_pwm <= glow_pwm[3:0] + glow_intensity;
		active_leds <= glow_pwm[4] ? ~0 : 0;
		counter <= counter + 1;
		if (i_Button) begin
			level <= 0;
			counter <= 0;
			counter_limit <= LEVELDOWN_COUNTER;
			sm_state <= s_START_GAME1;
		end
	end

	default: begin
		sm_state <= s_START_GAME1;
	end

	endcase
end

assign o_LED = ~active_leds;

endmodule
