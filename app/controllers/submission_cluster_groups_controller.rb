class SubmissionClusterGroupsController < ApplicationController
  # GET /assignments/1/cluster_groups
  def index
    @assignment = Assignment.find(params[:assignment_id])
    @course = @assignment.course
    @cluster_groups = @assignment.submission_cluster_groups
  end

  # GET /assignments/1/cluster_groups/new
  def new
    @assignment = Assignment.find(params[:assignment_id])
    @course = @assignment.course
    @assignment_plagiarism_cases = []
    @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_OR_SUSPECTED_PLAGIARISM_CRITERION] =
      @assignment.suspected_plagiarism_cases + @assignment.confirmed_plagiarism_cases
    @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_PLAGIARISM_CRITERION] =
      @assignment.confirmed_plagiarism_cases
    @submission_cluster_group = SubmissionClusterGroup.new
  end

  # POST /assignments/1/cluster_groups
  def create
    @assignment = Assignment.find(params[:assignment_id])
    @course = @assignment.course

    # Determine cut-off criterion if type requires
    if params[:submission_cluster_group]["cut_off_criterion_type"] == SubmissionClusterGroup::TYPE_CONFIRMED_OR_SUSPECTED_PLAGIARISM_CRITERION.to_s
      params[:submission_cluster_group]["cut_off_criterion"] = @assignment.confirmed_or_suspected_plagiarism_cases.collect { |submission_similarity|
        submission_similarity.similarity
      }.min
    elsif params[:submission_cluster_group]["cut_off_criterion_type"] == SubmissionClusterGroup::TYPE_CONFIRMED_PLAGIARISM_CRITERION.to_s
      params[:submission_cluster_group]["cut_off_criterion"] = @assignment.confirmed_plagiarism_cases.collect { |submission_similarity|
        submission_similarity.similarity
      }.min
    end

    @submission_cluster_group = SubmissionClusterGroup.new { |scg|
      scg.cut_off_criterion_type = params[:submission_cluster_group]["cut_off_criterion_type"]
      scg.cut_off_criterion = params[:submission_cluster_group]["cut_off_criterion"]
      scg.description = SubmissionClusterGroup::DESCRIPTIONS[params[:submission_cluster_group]["cut_off_criterion_type"].to_i]
      scg.assignment_id = @assignment.id
    }
    
    # Run java program if @submission_cluster_group is valid
    if @submission_cluster_group.valid?
      require 'submissions_handler'
      
      # Rollback if clustering error
      error_message = ""
      @submission_cluster_group.transaction do
        @submission_cluster_group.save
        begin
          SubmissionsHandler.process_cluster_group(@submission_cluster_group)
          redirect_to assignment_cluster_groups_url(@assignment), notice: 'Submission cluster group was successfully created.'
        rescue Exception => e
          error_message = e.message
          raise ActiveRecord::Rollback
        end
      end

      # Render #new and display errors
      unless @submission_cluster_group.id
        @assignment_plagiarism_cases = []
        @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_OR_SUSPECTED_PLAGIARISM_CRITERION] =
          @assignment.suspected_plagiarism_cases + @assignment.confirmed_plagiarism_cases
        @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_PLAGIARISM_CRITERION] =
          @assignment.confirmed_plagiarism_cases
        @submission_cluster_group.errors.add :base, error_message
        render action: "new" 
      end
    else
      @assignment_plagiarism_cases = []
      @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_OR_SUSPECTED_PLAGIARISM_CRITERION] =
        @assignment.suspected_plagiarism_cases + @assignment.confirmed_plagiarism_cases
      @assignment_plagiarism_cases[SubmissionClusterGroup::TYPE_CONFIRMED_PLAGIARISM_CRITERION] =
        @assignment.confirmed_plagiarism_cases
      render action: "new"
    end
  end

  # DELETE /assignments/1/cluster_groups/1
  def destroy
    @assignment = Assignment.find(params[:assignment_id])
    @course = @assignment.course
    @submission_cluster_group = SubmissionClusterGroup.find(params[:id])
    @submission_cluster_group.destroy

    redirect_to assignment_cluster_groups_url(@assignment), notice: 'Submission cluster group was successfully deleted.'
  end
end